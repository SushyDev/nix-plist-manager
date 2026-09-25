import Foundation

struct Case {
	let value: Any
	// control label → what it should show, in the order Nix lists them
	let controls: [(label: String, expected: Any)]
}

struct Spec {
	let pane: String
	let open: [String]
	let operate: (there: [String], back: [String])?
	let expect: [Case]
	let sideEffects: Bool
	let settle: Double

	var page: String { ([pane] + open).joined(separator: "\u{1}") }
}

struct Entry {
	let option: String
	let path: [String]
	let module: String
	let storage: [[String: Any]]
	let commands: [String: String]
	let verify: Spec?

	var label: String { path.joined(separator: " > ") }
}

func spec(_ raw: Any?) -> Spec? {
	guard let raw = raw as? [String: Any] else { return nil }
	let operate: (there: [String], back: [String])? = {
		switch raw["operate"] {
		case let pair as [[String]]: return (pair[0], pair[1])
		case let one as [String]: return (one, one)
		default: return nil
		}
	}()
	let cases = (raw["expect"] as? [[String: Any]] ?? []).map { item -> Case in
		let controls = item["controls"] as? [String: Any] ?? [:]
		return Case(value: item["value"] ?? NSNull(), controls: controls.keys.sorted().map { ($0, controls[$0]!) })
	}
	return Spec(
		pane: raw["pane"] as! String, open: raw["open"] as? [String] ?? [], operate: operate, expect: cases,
		sideEffects: truthy(raw["sideEffects"]), settle: (raw["settle"] as? NSNumber)?.doubleValue ?? 0.3)
}

func nixEval(_ arguments: [String]) throws -> Any {
	let (status, output, errors) = capture(["nix", "eval", "--json", "--impure"] + arguments)
	guard status == 0 else { throw Failure("nix eval \(arguments.first ?? "") failed:\n\(errors)") }
	return try parseJSON(output)
}

func loadOptions() throws -> [Entry] {
	(try nixEval(["path:\(root.path)#optionIndex"]) as! [[String: Any]]).map { raw in
		Entry(
			option: raw["option"] as! String, path: raw["path"] as! [String], module: raw["module"] as! String,
			storage: raw["storage"] as? [[String: Any]] ?? [], commands: raw["commands"] as? [String: String] ?? [:],
			verify: spec(raw["verify"]))
	}
}

var commands: [String: String] = [:]

// Evaluates the scripts for (option, value) pairs in one go; evaluating each alone costs a second.
func prepareCommands(_ pairs: [(option: String, value: Any)]) throws {
	var wanted: [[String: Any]] = []
	var seen = Set(commands.keys)
	for (option, value) in pairs where seen.insert(option + " " + canonical(value)).inserted {
		wanted.append(["option": option, "value": value])
	}
	guard !wanted.isEmpty else { return }
	let file = FileManager.default.temporaryDirectory.appendingPathComponent("verify-\(UUID().uuidString).json")
	try json(wanted).write(to: file, atomically: true, encoding: .utf8)
	defer { try? FileManager.default.removeItem(at: file) }
	let scripts = try nixEval([
		"path:\(root.path)#lib.commandFor",
		"--apply", "f: map (p: f p.option p.value) (builtins.fromJSON (builtins.readFile \(file.path)))",
	]) as! [String]
	for (pair, script) in zip(wanted, scripts) {
		commands[(pair["option"] as! String) + " " + canonical(pair["value"])] = script
	}
}

func command(_ option: String, _ value: Any) throws -> String {
	try prepareCommands([(option, value)])
	return commands[option + " " + canonical(value)]!
}

func build() -> String {
	text(capture(["/usr/bin/sw_vers", "-buildVersion"]).output)
}
