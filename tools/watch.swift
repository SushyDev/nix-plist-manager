// nix run .#watch [-- <domain part>…]: print each preference key that changes; -g is the global domain.

import CoreServices
import Foundation

let home = FileManager.default.homeDirectoryForCurrentUser.path
let roots = [
	"\(home)/Library/Preferences",
	"\(home)/Library/Containers",
	"\(home)/Library/Group Containers",
	"/Library/Preferences",
]
let filters = CommandLine.arguments.dropFirst().map { $0 == "-g" ? ".GlobalPreferences" : $0 }

let noisyKeys = try! NSRegularExpression(
	pattern: "LastUpdate|Timestamp|LastSeen|lastUsed|LaunchCount|WindowFrame|NSWindow|NSSplitView|NSNavPanel|NSToolbar|"
		+ "NSStatusItem Preferred Position|MRU|Recent|History|Session|LastReloaded|Workaround_",
	options: .caseInsensitive)
let noisyDomains: Set<String> = [
	"com.apple.systempreferences", "com.apple.Settings", "com.apple.cfprefsd.daemon", "com.apple.systemsettings.extensions",
	"com.apple.spaces", "com.apple.CloudKit", "com.apple.xpc.activity2", "ContextStoreAgent", "com.apple.knowledge-agent",
	"com.apple.suggestions", "com.apple.appleaccount", "com.apple.ncprefs.cache", "com.apple.configurationprofiles.user",
	"com.apple.siri.shortcuts", "com.apple.spotlightknowledged.pipeline", "com.apple.lighthouse.pnr.PnROnDeviceWorker",
	"com.apple.siri.analytics.assistant", "com.apple.siri.ODDI.MetricsWorker", "com.apple.unilog.MacMailSearch",
	"com.apple.biometrickitd", "com.apple.icloud.searchpartyuseragent", "com.apple.powerlogd", "com.apple.analyticsagent",
	"com.apple.systemsettingsagent", "com.apple.routined", "com.apple.bird.containers.notifications", "com.apple.fileproviderd",
	"com.apple.campo", "com.apple.photolibraryd",
]

func isNoise(_ key: String) -> Bool {
	noisyKeys.firstMatch(in: key, range: NSRange(key.startIndex..., in: key)) != nil
}

func isPreferenceFile(_ path: String) -> Bool {
	path.hasSuffix(".plist") && path.contains("/Preferences/")
		&& (filters.isEmpty || filters.contains { path.contains($0) })
}

// current-host copies end in the Mac's hardware UUID
func domain(of path: String) -> String {
	let name = (path as NSString).lastPathComponent.replacingOccurrences(of: ".plist", with: "")
	return name.replacingOccurrences(of: #"\.[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}$"#, with: "", options: .regularExpression)
}

func describe(_ path: String) -> String {
	let domain = domain(of: path)
	var notes: [String] = []
	if path.contains("/ByHost/") { notes.append("current host") }
	if path.hasPrefix("/Library/") { notes.append("system") }
	if path.contains("/Containers/") { notes.append("container") }
	return notes.isEmpty ? domain : "\(domain) (\(notes.joined(separator: ", ")))"
}

func read(_ path: String) -> [String: Any]? {
	guard let data = FileManager.default.contents(atPath: path) else { return nil }
	return (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any]
}

func show(_ value: Any?) -> String {
	switch value {
	case nil: return "(none)"
	case let data as Data: return "<\(data.count) bytes>"
	case let text as String: return "\"\(text)\""
	case let value?:
		let text = (try? JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed, .sortedKeys]))
			.flatMap { String(data: $0, encoding: .utf8) } ?? String(describing: value)
		return text.count > 160 ? String(text.prefix(157)) + "…" : text
	}
}

func changes(_ old: Any?, _ new: Any?, _ key: String = "") -> [(String, Any?, Any?)] {
	if let old = old as? [String: Any], let new = new as? [String: Any] {
		return Set(old.keys).union(new.keys).sorted().flatMap {
			changes(old[$0], new[$0], key.isEmpty ? $0 : "\(key).\($0)")
		}
	}
	let same = (old as? NSObject).map { o in (new as? NSObject).map { o.isEqual($0) } ?? false } ?? (new == nil)
	return same ? [] : [(key, old, new)]
}

var known: [String: [String: Any]] = [:]
for root in roots {
	for case let relative as String in FileManager.default.enumerator(atPath: root) ?? NSEnumerator() {
		let path = "\(root)/\(relative)"
		if isPreferenceFile(path), let contents = read(path) { known[path] = contents }
	}
}

let time = DateFormatter()
time.dateFormat = "HH:mm:ss"

let callback: FSEventStreamCallback = { _, _, count, paths, _, _ in
	let paths = unsafeBitCast(paths, to: NSArray.self) as! [String]
	for path in Set(paths.prefix(count)) where isPreferenceFile(path) && !noisyDomains.contains(domain(of: path)) {
		let contents = read(path)
		let found = changes(known[path] ?? [:], contents ?? [:]).filter { !isNoise($0.0) }
		known[path] = contents
		guard !found.isEmpty else { continue }
		print("\(time.string(from: Date())) \(describe(path))")
		for (key, old, new) in found {
			print("  \(key): \(show(old)) → \(show(new))")
		}
		fflush(stdout)
	}
}

let stream = FSEventStreamCreate(
	nil, callback, nil, roots as CFArray,
	FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0.3,
	FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagUseCFTypes)
)!
FSEventStreamSetDispatchQueue(stream, .main)
FSEventStreamStart(stream)
print("watching \(known.count) preference files; flip a setting (Ctrl-C to stop)")
fflush(stdout)
dispatchMain()
