import Foundation

struct StorageKey: Hashable {
	let domain: String
	let key: String
	let byHost: Bool
	let system: Bool

	var domainKey: DomainKey { DomainKey(domain: domain, byHost: byHost, system: system) }
}

struct DomainKey: Hashable {
	let domain: String
	let byHost: Bool
	let system: Bool
}

// what's stored under each key; a missing key is absent
typealias Values = [StorageKey: Any]

let hasRoot = getuid() == 0 || capture(["/usr/bin/sudo", "-n", "true"]).status == 0

func asRoot(_ argv: [String], _ root: Bool = true) -> [String] {
	!root || getuid() == 0 ? argv : ["/usr/bin/sudo", "-n"] + argv
}

func runScript(_ script: String, root: Bool = false, check: Bool = true) throws {
	let status = execute(asRoot(["/bin/bash", "-c", script], root))
	if check && status != 0 { throw Failure("the script failed with status \(status)") }
}

func storage(of entry: Entry, root: Bool) -> [StorageKey] {
	unique(entry.storage.compactMap { key in
		let system = key["scope"] as? String == "system"
		guard let name = key["key"] as? String, !(system && !root), let domain = key["domain"] as? String else { return nil }
		return StorageKey(
			domain: system && !domain.hasPrefix("/") ? "/Library/Preferences/\(domain)" : domain,
			key: name, byHost: key["byHost"] as? Bool ?? false, system: system)
	})
}

func exportDomain(_ domain: DomainKey) -> [String: Any] {
	let path = domain.domain.hasPrefix("~/") ? NSHomeDirectory() + domain.domain.dropFirst(1) : domain.domain
	let argv = ["/usr/bin/defaults"] + (domain.byHost ? ["-currentHost"] : []) + ["export", path, "-"]
	let (status, output, _) = capture(asRoot(argv, domain.system))
	guard status == 0, !output.isEmpty else { return [:] }
	return (try? PropertyListSerialization.propertyList(from: output, format: nil)) as? [String: Any] ?? [:]
}

func storageValues(_ keys: [StorageKey]) -> Values {
	var domains: [DomainKey: [String: Any]] = [:]
	var values: Values = [:]
	for key in keys {
		if domains[key.domainKey] == nil { domains[key.domainKey] = exportDomain(key.domainKey) }
		if let value = domains[key.domainKey]![key.key] { values[key] = value }
	}
	return values
}

func sameValues(_ a: Values, _ b: Values, _ keys: [StorageKey]) -> Bool {
	keys.allSatisfy { same(a[$0], b[$0]) }
}

// `defaults import` merges, so a one-key plist restores only that key.
func restore(_ values: [StorageKey: Any?]) {
	for (key, value) in values {
		let host = key.byHost ? ["-currentHost"] : []
		let path = key.domain.hasPrefix("~/") ? NSHomeDirectory() + key.domain.dropFirst(1) : key.domain
		guard let value else {
			capture(asRoot(["/usr/bin/defaults"] + host + ["delete", path, key.key], key.system))
			continue
		}
		let file = FileManager.default.temporaryDirectory.appendingPathComponent("restore-\(UUID().uuidString).plist")
		let data = try! PropertyListSerialization.data(fromPropertyList: [key.key: value], format: .xml, options: 0)
		try! data.write(to: file)
		try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: file.path)
		execute(asRoot(["/usr/bin/defaults"] + host + ["import", path, file.path], key.system))
		try? FileManager.default.removeItem(at: file)
	}
}

func restoreAll(_ before: Values, _ keys: [StorageKey]) {
	restore(Dictionary(uniqueKeysWithValues: keys.map { ($0, before[$0]) }))
}

// The Dock and SystemUIServer write what they have loaded when they quit.
func restoreAfterRestarting(_ before: Values, _ keys: [StorageKey], processes: [String]) {
	for process in processes { capture(["/usr/bin/killall", process]) }
	if !processes.isEmpty { pause(2) }
	restoreAll(before, keys)
	for process in processes { capture(["/usr/bin/killall", process]) }
	if !processes.isEmpty { pause(1) }
}

let noise = "LastUpdate|Timestamp|LastSeen|lastUsed|LaunchCount|WindowFrame|NSWindow|NSSplitView|NSNavPanel|NSToolbar|MRU|Recent|History|Session"

// Whole domains, because turning a feature on can make its agent write other keys there
// (Switch Control writes its scanning intervals).
func domainSnapshot(_ keys: [StorageKey]) -> [DomainKey: [String: Any]] {
	Dictionary(unique(keys.map(\.domainKey)).map { ($0, exportDomain($0)) }, uniquingKeysWith: { a, _ in a })
}

// Puts back keys that changed in the snapshot's domains besides the declared ones.
func restoreDomains(_ snapshot: [DomainKey: [String: Any]], declared: Set<StorageKey>) -> [StorageKey] {
	var side: [StorageKey] = []
	for (domain, old) in snapshot {
		let now = exportDomain(domain)
		let changed = Set(old.keys).union(now.keys).sorted().filter { key in
			!same(old[key], now[key]) && !matches(noise, key, options: .caseInsensitive)
				&& !declared.contains(StorageKey(domain: domain.domain, key: key, byHost: domain.byHost, system: domain.system))
		}.map { StorageKey(domain: domain.domain, key: $0, byHost: domain.byHost, system: domain.system) }
		restore(Dictionary(uniqueKeysWithValues: changed.map { ($0, old[$0.key]) }))
		side += changed
	}
	return side
}

let backup = cache.appendingPathComponent("restore.plist")

// Kept on disk until the values are back, so an interrupted run can still put them back.
func saveBackup(_ before: Values, _ keys: [StorageKey], scripts: [String], root: Bool, domains: [DomainKey: [String: Any]]) {
	try? FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
	let entries: [[String: Any]] = keys.map { key in
		["key": [key.domain, key.key, key.byHost, key.system]].merging(before[key].map { ["value": $0] } ?? [:]) { a, _ in a }
	}
	let snapshots: [[String: Any]] = domains.map { ["domain": [$0.key.domain, $0.key.byHost, $0.key.system], "values": $0.value] }
	let contents: [String: Any] = ["entries": entries, "scripts": scripts, "root": root, "domains": snapshots]
	try? PropertyListSerialization.data(fromPropertyList: contents, format: .binary, options: 0).write(to: backup)
}

func restoreBackup() throws {
	guard let data = try? Data(contentsOf: backup),
	      let saved = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else { return }
	say("putting back the values an interrupted run left in \(backup.path)")
	var values: [StorageKey: Any?] = [:]
	for entry in saved["entries"] as? [[String: Any]] ?? [] {
		let key = entry["key"] as! [Any]
		values[StorageKey(domain: key[0] as! String, key: key[1] as! String, byHost: key[2] as! Bool, system: key[3] as! Bool)] = entry["value"]
	}
	restore(values)
	var snapshot: [DomainKey: [String: Any]] = [:]
	for domain in saved["domains"] as? [[String: Any]] ?? [] {
		let key = domain["domain"] as! [Any]
		snapshot[DomainKey(domain: key[0] as! String, byHost: key[1] as! Bool, system: key[2] as! Bool)] = domain["values"] as? [String: Any] ?? [:]
	}
	_ = restoreDomains(snapshot, declared: [])
	try runScript(runOnceAtTheEnd((saved["scripts"] as? [String] ?? []).joined(separator: "\n")), root: saved["root"] as? Bool ?? false, check: false)
	try? FileManager.default.removeItem(at: backup)
}

func runOnceAtTheEnd(_ script: String) -> String {
	let lines = script.components(separatedBy: "\n")
	var last: [String: Int] = [:]
	for (index, line) in lines.enumerated() { last[line] = index }
	return lines.enumerated().filter { last[$0.element] == $0.offset }.map(\.element).joined(separator: "\n")
}
