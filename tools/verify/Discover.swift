import Foundation

struct Found {
	let title: String
	let kind: String
	let choices: [String]
}

func dump(sheet: Bool = false) throws -> [[String: Any]] {
	let output = try sheet ? ((try? ax("dump", "--sheet")) ?? ax("dump")) : ax("dump")
	return output.split(separator: "\n").compactMap { try? parseJSON(Data($0.utf8)) as? [String: Any] }
		.filter { !($0["path"] as? [String] ?? []).contains("Sidebar") }
}

func isIdentifier(_ label: String) -> Bool {
	!label.contains(" ") && (matches(#"[a-z][A-Z]|-|_|\."#, label) || (label == label.lowercased() && label.contains(where: \.isLetter)))
}

func humanLabel(_ labels: [String]) -> String {
	let readable = unique(labels.filter { !isIdentifier($0) })
	guard let first = readable.first else { return labels[0] }
	if readable.count > 1, labels.firstIndex(of: first)! < labels.firstIndex(of: readable.last!)! - 1 {
		return "\(readable.last!) > \(first)"
	}
	return first
}

func discover(_ pane: String, steps: [String] = []) throws -> [Found] {
	try openPane(pane, steps: steps)
	pause(1)
	let chrome: Set<String> = ["Go Back", "Go Forward", "Help", "Search"]
	let entries = try dump(sheet: !steps.isEmpty).filter { chrome.isDisjoint(with: $0["labels"] as? [String] ?? []) }
	var found: [Found] = []
	var group: (title: String?, members: [[String: Any]], role: String, labeled: Bool)?
	var lastText: String?

	func flush() {
		// unlike a row of unrelated buttons, a picker has a selected or labeled member
		if let current = group, current.labeled || current.members.contains(where: { truthy($0["selected"]) || same($0["value"], 1) }) {
			let choices = current.members.map { humanLabel($0["labels"] as! [String]) }
			var title = current.title ?? ""
			if found.contains(where: { $0.title == title }) { title = "\(title) (\(choices.joined(separator: "/")))" }
			found.append(Found(title: title, kind: "enum", choices: choices))
		}
		group = nil
	}

	for entry in entries {
		let role = entry["role"] as? String ?? "", labels = entry["labels"] as? [String] ?? []
		if role == "AXStaticText" {
			lastText = entry["value"] as? String
		} else if role == "AXButton", let first = labels.first, first.hasSuffix("…") {
			flush()
			found.append(Found(title: first, kind: "sheet", choices: []))
		} else if ["AXButton", "AXRadioButton"].contains(role), !labels.isEmpty {
			let title = labels.count > 1 ? labels[1] : lastText
			if group == nil || group!.title != title || group!.role != role {
				flush()
				group = (title, [], role, labels.count > 1)
			}
			group!.members.append(entry)
		} else {
			flush()
			let kinds = ["AXCheckBox": "bool", "AXSlider": "number", "AXPopUpButton": "enum"]
			if let kind = kinds[role], !labels.isEmpty { found.append(Found(title: humanLabel(labels), kind: kind, choices: [])) }
		}
	}
	flush()
	return found.filter { !$0.title.isEmpty }
}

func runDiscover(_ pane: String, open: [String]) throws {
	for found in try discover(pane, steps: open) {
		let choices = found.choices.isEmpty ? "" : "  [" + found.choices.map { "'\($0)'" }.joined(separator: ", ") + "]"
		say(found.kind.padding(toLength: max(7, found.kind.count), withPad: " ", startingAt: 0) + " " + found.title + choices)
	}
}

func runGaps(pane wanted: String?) throws {
	let options = try loadOptions(), coverage = try loadCoverage()
	try openPane("com.apple.settings.appearance")
	// sidebar identifier → name
	var panes: [String: String] = [:]
	for line in try ax("dump").split(separator: "\n") {
		guard let entry = try? parseJSON(Data(line.utf8)) as? [String: Any], (entry["path"] as? [String] ?? []).contains("Sidebar"),
		      entry["role"] as? String == "AXButton", let labels = entry["labels"] as? [String], labels.count == 2 else { continue }
		panes[labels.last!] = labels[0]
	}
	var known: [String: Set<String>] = [:]
	for entry in options {
		let ui = entry.path
		if ui[0] == "System Settings" { known[ui[1], default: []].formUnion(ui.dropFirst(2).map(normalize)) }
		if let spec = entry.verify, let name = panes[spec.pane] {
			// spec labels can differ from what the UI shows
			let labels = spec.expect.flatMap { $0.controls.map(\.label) } + spec.open
			let parts = labels.flatMap { $0.components(separatedBy: " > ").flatMap { $0.components(separatedBy: " + ") } }
				.map { replacing(#"^\w+:|#\d+$"#, in: $0, with: "") }
			known[name, default: []].formUnion((Array(ui.dropFirst()) + parts).map(normalize))
		}
	}
	for listed in [coverage.todo, coverage.notCovered, coverage.notSettings] {
		for (pane, reasons) in listed {
			known[pane, default: []].formUnion(reasons.values.joined().flatMap { $0.components(separatedBy: " › ") }.map(normalize))
		}
	}
	var pages = Set(panes.keys.map { [$0] })
	for entry in options { if let spec = entry.verify, panes[spec.pane] != nil { pages.insert([spec.pane] + spec.open) } }
	for page in pages.sorted(by: { $0.lexicographicallyPrecedes($1) }) {
		let name = panes[page[0]]!, steps = Array(page.dropFirst())
		if let wanted, normalize(wanted) != normalize(name) { continue }
		let found: [Found]
		do { found = try discover(page[0], steps: steps) } catch {
			say("\(([name] + steps).joined(separator: " > ")): couldn't open (\(error))")
			continue
		}
		// discover adds the choices to repeated labels: "Style (Light/Dark)"
		for item in found where !(known[name] ?? []).contains(normalize(replacing(#" \([^)]*\)$"#, in: item.title, with: ""))) {
			say("\(([name] + steps + [item.title]).joined(separator: " > "))  (\(item.kind))")
		}
	}
}
