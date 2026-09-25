import CoreServices
import Foundation

let home = FileManager.default.homeDirectoryForCurrentUser.path
let roots = [
	"\(home)/Library/Preferences",
	"\(home)/Library/Containers",
	"\(home)/Library/Group Containers",
	"/Library/Preferences",
]

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

func isPreferenceFile(_ path: String, _ filters: [String]) -> Bool {
	path.hasSuffix(".plist") && path.contains("/Preferences/")
		&& (filters.isEmpty || filters.contains { path.contains($0) })
}

// current-host copies end in the Mac's hardware UUID
func domainOfFile(_ path: String) -> String {
	let name = (path as NSString).lastPathComponent.replacingOccurrences(of: ".plist", with: "")
	return name.replacingOccurrences(of: #"\.[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}$"#, with: "", options: .regularExpression)
}

func describeFile(_ path: String) -> String {
	let domain = domainOfFile(path)
	var notes: [String] = []
	if path.contains("/ByHost/") { notes.append("current host") }
	if path.hasPrefix("/Library/") { notes.append("system") }
	if path.contains("/Containers/") { notes.append("container") }
	return notes.isEmpty ? domain : "\(domain) (\(notes.joined(separator: ", ")))"
}

func readPlist(_ path: String) -> [String: Any]? {
	guard let data = FileManager.default.contents(atPath: path) else { return nil }
	return (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any]
}

func showValue(_ value: Any?) -> String {
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

// Reports each preference key that changes in the files whose path contains one of `filters`.
final class Watcher {
	let filters: [String]
	let report: (String) -> Void
	var known: [String: [String: Any]] = [:]
	var stream: FSEventStreamRef?

	init(filters: [String], report: @escaping (String) -> Void) {
		self.filters = filters.map { $0 == "-g" ? ".GlobalPreferences" : $0 }
		self.report = report
		for root in roots {
			for case let relative as String in FileManager.default.enumerator(atPath: root) ?? NSEnumerator() {
				let path = "\(root)/\(relative)"
				if isPreferenceFile(path, self.filters), let contents = readPlist(path) { known[path] = contents }
			}
		}
	}

	func changed(_ paths: [String]) {
		let time = DateFormatter()
		time.dateFormat = "HH:mm:ss"
		for path in Set(paths) where isPreferenceFile(path, filters) && !noisyDomains.contains(domainOfFile(path)) {
			let contents = readPlist(path)
			let found = changes(known[path] ?? [:], contents ?? [:]).filter { !isNoise($0.0) }
			known[path] = contents
			guard !found.isEmpty else { continue }
			report("\(time.string(from: Date())) \(describeFile(path))")
			for (key, old, new) in found {
				report("  \(key): \(showValue(old)) → \(showValue(new))")
			}
		}
	}

	func start(on queue: DispatchQueue) {
		var context = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
		let callback: FSEventStreamCallback = { _, info, count, paths, _, _ in
			let watcher = Unmanaged<Watcher>.fromOpaque(info!).takeUnretainedValue()
			watcher.changed(Array((unsafeBitCast(paths, to: NSArray.self) as! [String]).prefix(count)))
		}
		stream = FSEventStreamCreate(
			nil, callback, &context, roots as CFArray,
			FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0.3,
			FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagUseCFTypes)
		)
		FSEventStreamSetDispatchQueue(stream!, queue)
		FSEventStreamStart(stream!)
	}

	func stop() {
		guard let stream else { return }
		FSEventStreamStop(stream)
		FSEventStreamInvalidate(stream)
		FSEventStreamRelease(stream)
		self.stream = nil
	}
}

func watch(_ filters: [String]) -> Never {
	let watcher = Watcher(filters: filters, report: say)
	watcher.start(on: .main)
	say("watching \(watcher.known.count) preference files; flip a setting (Ctrl-C to stop)")
	dispatchMain()
}
