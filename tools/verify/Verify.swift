import Foundation

let activateSettings = "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"

// Launch System Settings if needed and wait for its window; one closed earlier only comes back with a relaunch.
func openSettings() throws {
	execute(["/usr/bin/open", "-b", "com.apple.systempreferences"])
	for _ in 0..<2 {
		let deadline = Date().addingTimeInterval(8)
		while Date() < deadline {
			if (try? ax("values")) != nil { return }
			pause(0.2)
		}
		quitSettings()
		execute(["/usr/bin/open", "-b", "com.apple.systempreferences"])
	}
	throw Failure("System Settings shows no window")
}

// A normal quit makes System Settings write what it shows back to the preferences.
func quitSettings() {
	capture(["/usr/bin/killall", "-KILL", "System Settings"])
	pause(0.5)
}

// x-apple.systempreferences: URLs sometimes land on the wrong pane, so the sidebar is used.
func openPane(_ pane: String, fresh: Bool = false, waitFor: String? = nil, steps: [String] = []) throws {
	if fresh { quitSettings() }
	try openSettings()
	// sidebar rows only exist once scrolled to, which a click does
	try waitUntil("sidebar item \(pane)") { try (try? ax("press", pane)) ?? ax("click", pane) }
	for step in steps {
		let (action, target) = step.hasPrefix("click:") ? ("click", String(step.dropFirst(6))) : ("press", step)
		try waitUntil(step) { try ax(action, target) }
		pause(0.2)
	}
	if let waitFor { try waitUntil(waitFor) { try ax("get", waitFor) } }
}

// pages that keep showing old values, or write them back when they're left, until System Settings is quit
// without saving and relaunched; pages that show a written value without being reloaded, and ones that don't
var stalePages = Set<String>()
var livePages = Set<String>()
var reloadedPages = Set<String>()

// The keys once they've stopped changing; activateSettings rewrites shortcuts a moment later.
func settled(_ keys: [StorageKey], quiet: Double = 0.5, timeout: Double = 4) -> Values {
	var last = storageValues(keys), since = Date()
	let deadline = Date().addingTimeInterval(timeout)
	while Date().timeIntervalSince(since) < quiet && Date() < deadline {
		pause(0.2)
		let now = storageValues(keys)
		if !sameValues(now, last, keys) { last = now; since = Date() }
	}
	return last
}

// Write, then show the page with what was written: some pages show it by themselves, most after being switched
// away from and back, the rest after a relaunch. `shown` says whether the page shows what's expected.
func applyAndShow(_ spec: Spec, _ script: String, _ keys: [StorageKey], root: Bool, waitFor: String? = nil, shown: (() -> Bool)? = nil) throws {
	let page = spec.page
	if let shown, !reloadedPages.contains(page), !stalePages.contains(page) {
		try runScript(script, root: root)
		if script.contains("activateSettings") { _ = settled(keys) }
		if poll(0.8, { shown() ? true : nil }) != nil {
			livePages.insert(page)
			return
		}
		reloadedPages.insert(page)
		livePages.remove(page)
	}
	if stalePages.contains(page) { quitSettings() }  // before writing, so the open page can't write its values back
	try runScript(script, root: root)
	pause(spec.settle)
	let written = script.contains("activateSettings") ? settled(keys) : storageValues(keys)
	try refresh(spec, waitFor: waitFor)
	if !stalePages.contains(page) && !sameValues(storageValues(keys), written, keys) {
		stalePages.insert(page)
		try applyAndShow(spec, script, keys, root: root, waitFor: waitFor)
	}
}

// Show the page with what's stored now: switching to another pane and back reloads most pages; the rest need
// System Settings relaunched.
func refresh(_ spec: Spec, waitFor: String? = nil, relaunch: Bool = false) throws {
	if relaunch || stalePages.contains(spec.page) {
		try openPane(spec.pane, fresh: true, waitFor: waitFor, steps: spec.open)
		return
	}
	for label in ["Done", "OK", "Cancel"] where (try? ax("press", "AXButton:\(label)")) != nil {  // an open sheet blocks the sidebar
		pause(0.3)
		break
	}
	let other = spec.pane != "com.apple.settings.general" ? "com.apple.settings.general" : "com.apple.settings.appearance"
	do {
		try ax("press", other)
		pause(0.2)
		try openPane(spec.pane, waitFor: waitFor, steps: spec.open)
	} catch {
		try refresh(spec, waitFor: waitFor, relaunch: true)
	}
}

func matchesExpected(_ actual: [String: Any], _ expected: Any) -> Bool {
	if let expected = expected as? [String: Any] {
		return expected.allSatisfy { key, value in isBool(value) ? truthy(actual[key]) == (value as! NSNumber).boolValue : same(actual[key], value) }
	}
	let value = actual["value"]
	if let expected = expected as? NSNumber, let value = value as? NSNumber {
		return abs(value.doubleValue - expected.doubleValue) < 1e-6
	}
	if let expected = expected as? String, let value = value as? String {
		return value.trimmingCharacters(in: .whitespaces) == expected.trimmingCharacters(in: .whitespaces)  // some menus pad their titles
	}
	return same(value, expected)
}

typealias Controls = [String: [String: Any]]

func readControls(_ labels: [String]) -> Controls {
	let labels = unique(labels)
	guard !labels.isEmpty else { return [:] }
	do {
		return try parseJSON(Data(try ax(["values"] + labels).utf8)) as? Controls ?? [:]
	} catch {
		return Dictionary(uniqueKeysWithValues: labels.map { ($0, ["error": "\(error)"]) })
	}
}

func expectationsMet(_ expectations: [(label: String, expected: Any)], _ controls: Controls) -> [String] {
	expectations.compactMap { control, expected in
		let actual = controls[control] ?? ["error": "not read"]
		if let error = actual["error"] { return "\(control): \(error)" }
		if matchesExpected(actual, expected) { return nil }
		let shown = actual.filter { ["value", "selected"].contains($0.key) }
		return "\(control): expected \(json(expected)), got \(json(shown))"
	}
}

// What the page shows now; nothing when the page only exists for some values.
func openForReading(_ spec: Spec, _ group: [Entry]) -> [String: Any] {
	guard (try? refresh(spec)) != nil else { return [:] }
	return shownValues(group, opened: true)
}

// Which of its spec's values each option shows, read in one go; missing when it's none of them.
func shownNow(_ group: [Entry]) -> [String: Any?] {
	let controls = readControls(group.flatMap { $0.verify!.expect.flatMap { $0.controls.map(\.label) } })
	return Dictionary(uniqueKeysWithValues: group.map { entry in
		(entry.option, entry.verify!.expect.first { expectationsMet($0.controls, controls).isEmpty }?.value)
	})
}

func allShown(_ group: [Entry]) -> [String: Any?] {
	poll(3) { let now = shownNow(group); return now.values.contains { $0 == nil } ? nil : now } ?? shownNow(group)
}

// Restoring keys alone doesn't undo live state such as dark mode, so what's shown is put back through the option.
func shownValues(_ group: [Entry], opened: Bool = false) -> [String: Any] {
	let spec = group[0].verify!
	if !opened {
		guard (try? openPane(spec.pane, steps: spec.open)) != nil else { return [:] }  // the page only exists for some values
	}
	return allShown(group).compactMapValues { $0 }
}

// Catches options that write somewhere System Settings doesn't read, such as a ByHost copy.
func operatingWrites(_ entry: Entry, root: Bool) throws -> [String] {
	let spec = entry.verify!, keys = storage(of: entry, root: root)
	let (there, back) = spec.operate!
	try refresh(spec, waitFor: there[1])
	if back != there {
		try ax(back)  // start from the "back" state, whatever was applied last
		pause(1)
	}
	let before = storageValues(keys)
	try ax(there)
	let afterThere = poll(3) { let now = storageValues(keys); return sameValues(now, before, keys) ? nil : now } ?? storageValues(keys)
	try ax(back)
	let afterBack = poll(3) { let now = storageValues(keys); return sameValues(now, afterThere, keys) ? nil : now } ?? storageValues(keys)
	// "back" may be an equivalent value, like a deleted key for false
	if keys.contains(where: { !same(afterThere[$0], before[$0]) && !same(afterBack[$0], afterThere[$0]) }) { return [] }
	return ["operating \(there) in System Settings doesn't change what the option writes (\(keys.map(\.key).joined(separator: ", ")))"]
}

func putBack(_ keys: [StorageKey], _ before: Values, scripts: [String], shownScripts: [String], root: Bool, domains: [DomainKey: [String: Any]]) {
	let every = scripts.joined(separator: "\n")
	try? runScript(runOnceAtTheEnd(shownScripts.joined(separator: "\n")), root: root, check: false)
	let regex = try! NSRegularExpression(pattern: #"killall(?: -KILL)? '?([^' \n]+)'?"#)
	let processes = Set(regex.matches(in: every, range: NSRange(every.startIndex..., in: every)).map {
		String(every[Range($0.range(at: 1), in: every)!])
	}).subtracting(["System Settings"]).sorted()
	restoreAfterRestarting(before, keys, processes: processes)
	// activateSettings writes keyboard shortcuts back a moment later
	if every.contains("activateSettings") {
		capture([activateSettings, "-u"])
		if !sameValues(settled(keys), before, keys) { restoreAll(before, keys) }
	}
	for key in restoreDomains(domains, declared: Set(keys)) {
		say("     put back \(key.domain) \(key.key), which the page changed besides its own keys")
	}
	let now = storageValues(keys)
	let mismatched = keys.filter { !same(now[$0], before[$0]) }
	for key in mismatched {
		say("RESTORE MISMATCH \(key.domain) \(key.key): was \(json(before[key])), now \(json(now[key]))")
	}
	if mismatched.isEmpty { try? FileManager.default.removeItem(at: backup) }
}

// A page's options are checked together, so shorter specs repeat their values.
func caseOf(_ entry: Entry, _ index: Int) -> Case {
	let cases = entry.verify!.expect
	return cases[index % cases.count]
}

func keysOf(_ group: [Entry], root: Bool) -> [StorageKey] {
	unique(group.flatMap { storage(of: $0, root: root) })
}

func checkGroup(_ group: [Entry]) throws -> Set<String> {
	let spec = group[0].verify!
	let root = group.contains { $0.module == "darwin" }
	let rounds = group.map { $0.verify!.expect.count }.max()!
	var scripts: [String: [String: String]] = [:]
	for entry in group {
		for item in entry.verify!.expect { scripts[entry.option, default: [:]][canonical(item.value)] = try command(entry.option, item.value) }
	}
	let keys = keysOf(group, root: root)
	let before = storageValues(keys)
	let domains = domainSnapshot(keys)
	let shown = openForReading(spec, group)
	let shownScripts = shown.compactMap { option, value in scripts[option]?[canonical(value)] }
	saveBackup(before, keys, scripts: shownScripts, root: root, domains: domains)
	var failures = Dictionary(uniqueKeysWithValues: group.map { ($0.option, [String]()) })
	let putBackNow = { putBack(keys, before, scripts: scripts.values.flatMap(\.values), shownScripts: shownScripts, root: root, domains: domains) }
	do {
		try checkRounds(group, rounds: rounds, scripts: scripts, keys: keys, root: root, failures: &failures)
	} catch {
		putBackNow()
		throw error
	}
	putBackNow()
	for entry in group {
		say("\(failures[entry.option]!.isEmpty ? "ok  " : "FAIL") \(entry.label)")
		for failure in failures[entry.option]! { say("     \(failure)") }
	}
	return Set(failures.filter { $0.value.isEmpty }.keys)
}

func checkRounds(_ group: [Entry], rounds: Int, scripts: [String: [String: String]], keys: [StorageKey], root: Bool, failures: inout [String: [String]]) throws {
	let spec = group[0].verify!
	for index in 0..<rounds {
		let value = { (entry: Entry) in canonical(caseOf(entry, index).value) }
		let waitFor = spec.open.isEmpty ? caseOf(group[0], index).controls.first?.label : nil
		let misses = { () -> [String: [String]] in
			let controls = readControls(group.flatMap { caseOf($0, index).controls.map(\.label) })
			return Dictionary(uniqueKeysWithValues: group.map { ($0.option, expectationsMet(caseOf($0, index).controls, controls)) })
		}
		let noneMissed = { () -> [String: [String]]? in let missed = misses(); return missed.values.allSatisfy(\.isEmpty) ? missed : nil }
		try applyAndShow(spec, runOnceAtTheEnd(group.map { scripts[$0.option]![value($0)]! }.joined(separator: "\n")), keys, root: root,
			waitFor: waitFor, shown: { misses().values.allSatisfy(\.isEmpty) })
		var missed = poll(3, noneMissed) ?? misses()
		// a stale view isn't a failure: relaunch and look again
		if missed.values.contains(where: { !$0.isEmpty }) && !stalePages.contains(spec.page) {
			try refresh(spec, waitFor: waitFor, relaunch: true)
			missed = poll(4, noneMissed) ?? misses()
			if missed.values.allSatisfy(\.isEmpty) { stalePages.insert(spec.page) }
		}
		for entry in group { failures[entry.option]! += missed[entry.option]!.map { "\(value(entry)): \($0)" } }
	}
	for entry in group where entry.verify!.operate != nil {
		failures[entry.option]! += try operatingWrites(entry, root: root)
	}
}

let preferenceOnly = #"^\s*(/usr/bin/(defaults|killall|notifyutil)\b|current=|case |if /bin/launchctl print gui/|/usr/bin/osascript -l JavaScript \S+-set-members\.js |"#
	+ NSRegularExpression.escapedPattern(for: activateSettings) + ")"

func appliesLive(_ entry: Entry) -> Bool {
	entry.commands.values.contains { script in
		script.components(separatedBy: "\n").contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty && !matches(preferenceOnly, $0) }
	}
}

func defaultGroup(_ group: [Entry]) throws -> [String: Any] {
	let spec = group[0].verify!
	let root = group.contains { $0.module == "darwin" }
	let keys = keysOf(group, root: root)
	let before = storageValues(keys)
	let domains = domainSnapshot(keys)
	let beforeShown = openForReading(spec, group)
	// restoring the keys puts back everything that isn't applied live
	let shownScripts = try group.filter { appliesLive($0) && beforeShown[$0.option] != nil }.map { try command($0.option, beforeShown[$0.option]!) }
	let unset = group.map { $0.commands["unset"]! }
	saveBackup(before, keys, scripts: shownScripts, root: root, domains: domains)
	let putBackNow = { putBack(keys, before, scripts: unset + shownScripts, shownScripts: shownScripts, root: root, domains: domains) }
	let result: [String: Any]
	do {
		try applyAndShow(spec, runOnceAtTheEnd(unset.joined(separator: "\n")), keys, root: root)
		var found = allShown(group)
		// the same value as before can be the default or a view that didn't reload: relaunch to tell
		let unsure = group.filter { entry in found[entry.option]! == nil || same(found[entry.option]!, beforeShown[entry.option]) }
		if !unsure.isEmpty && !stalePages.contains(spec.page) {
			try refresh(spec, relaunch: true)
			let again = allShown(unsure)
			if again.contains(where: { !same($0.value, found[$0.key]!) }) { stalePages.insert(spec.page) }
			found.merge(again) { _, new in new }
		}
		result = found.compactMapValues { $0 }
	} catch {
		putBackNow()
		throw error
	}
	putBackNow()
	for entry in group {
		say("\(entry.label): \(result[entry.option].map { json($0) } ?? "none of the spec's values")")
	}
	return result
}

struct Selection {
	var pane: String?
	var option: String?
	var skip: String?
	var batch = false
	var sideEffects = false
	var onlyUnverified = false
	var defaults = false
}

func normalize(_ title: String) -> String {
	replacing("[^a-z0-9]+", in: title.replacingOccurrences(of: "’", with: "'").lowercased(), with: " ").trimmingCharacters(in: .whitespaces)
}

func select(_ options: [Entry], _ selection: Selection, leaving verified: Set<String> = []) -> [[Entry]] {
	var order: [String] = []
	var groups: [String: [Entry]] = [:]
	for entry in options {
		guard let spec = entry.verify, !spec.expect.isEmpty else { continue }
		if let option = selection.option, option != entry.option { continue }
		if let pane = selection.pane, !normalize(entry.label).contains(normalize(pane)) { continue }
		if let skip = selection.skip, matches(skip, entry.label) { continue }
		if selection.onlyUnverified && verified.contains(entry.option) { continue }
		if selection.defaults && entry.commands["unset"] == nil { continue }
		if spec.sideEffects && !selection.sideEffects { continue }
		if entry.module == "darwin" && !hasRoot { continue }  // nix-darwin's settings need root
		let page = selection.batch ? spec.page : entry.option
		if groups[page] == nil { order.append(page) }
		groups[page, default: []].append(entry)
	}
	return order.map { groups[$0]! }
}

func start(_ groups: [[Entry]]) throws {
	try restoreBackup()
	try prepareCommands(groups.flatMap { $0.flatMap { entry in entry.verify!.expect.map { (entry.option, $0.value) } } })
}

func runDefaults(_ selection: Selection, missing: Bool) throws {
	let path = root.appendingPathComponent("defaults/\(build()).json")
	var defaults = (try? Data(contentsOf: path)).flatMap { try? parseJSON($0) as? [String: Any] } ?? [:]
	let groups = select(try loadOptions(), selection, leaving: missing ? Set(defaults.keys) : [])
	try start(groups)
	for group in groups {
		do {
			defaults.merge(try defaultGroup(group)) { _, new in new }
		} catch {
			say("ERROR \(group.map(\.label).joined(separator: ", "))\n     \(error)")
			continue
		}
		try? FileManager.default.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
		try ("{\n" + defaults.keys.sorted().map { "\t\(quote($0)): \(json(defaults[$0]))" }.joined(separator: ",\n") + "\n}\n")
			.write(to: path, atomically: true, encoding: .utf8)
	}
	quitSettings()
	say("\(defaults.count) defaults in defaults/\(path.lastPathComponent)")
}

func runCheck(_ selection: Selection) throws -> Int32 {
	var coverage = try loadCoverage()
	let verified = Set(coverage.verified.values.joined())
	let groups = select(try loadOptions(), selection, leaving: verified)
	try start(groups)
	var passed = Set<String>(), failed = Set<String>(), errors = 0
	for group in groups {
		do {
			var ok = try checkGroup(group)
			// values of options on one page can depend on each other: check failures on their own
			for entry in group where !ok.contains(entry.option) && group.count > 1 {
				say("     again on its own: \(entry.label)")
				ok.formUnion(try checkGroup([entry]))
			}
			passed.formUnion(ok)
			failed.formUnion(Set(group.map(\.option)).subtracting(ok))
		} catch {  // e.g. System Settings not opening: says nothing about the options
			say("ERROR \(group.map(\.label).joined(separator: ", "))\n     \(error)")
			errors += 1
		}
	}
	let current = build()
	coverage.verified = coverage.verified.mapValues { $0.filter { !passed.contains($0) && !failed.contains($0) } }
	coverage.verified[current] = Array(Set(coverage.verified[current] ?? []).union(passed))
	try saveCoverage(coverage)
	quitSettings()
	say("\(passed.count) passed, \(failed.count) failed" + (errors > 0 ? ", \(errors) pages couldn't be checked" : ""))
	return failed.isEmpty && errors == 0 ? 0 : 1
}

func runShown(_ names: [String]) throws {
	let index = Dictionary(uniqueKeysWithValues: try loadOptions().map { ($0.option, $0) })
	var shown: [String: Any] = [:]
	for name in names {
		guard let entry = index[name], entry.verify != nil else { continue }
		shown.merge(shownValues([entry])) { _, new in new }
	}
	print(json(shown))
}

func observe(_ pane: String, open: [String], command: [String]) throws {
	try openPane(pane, fresh: !open.isEmpty, steps: open)
	pause(1)
	var lines: [String] = []
	let queue = DispatchQueue(label: "watch")
	let watcher = Watcher(filters: []) { line in lines.append(line) }
	watcher.start(on: queue)
	try ax(command)
	pause(5)  // cfprefsd writes changes to disk a few seconds later
	queue.sync { watcher.stop() }
	lines.forEach { say($0) }
}
