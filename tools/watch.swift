// watch — print every preference key that changes, as it changes.
//
//   nix run .#watch                         everything
//   nix run .#watch -- com.apple.dock -g    only domains containing one of these words
//                                           (-g is the global domain)
//
// Flip a setting in System Settings and it prints the domain, key and new value, which is what a
// setting's `storage` needs. Watches the user's preferences (and their current-host copies),
// sandboxed apps' containers and /Library/Preferences.

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

func isPreferenceFile(_ path: String) -> Bool {
	path.hasSuffix(".plist") && path.contains("/Preferences/")
		&& (filters.isEmpty || filters.contains { path.contains($0) })
}

// what `defaults` calls it: the file name, without a current-host copy's hardware UUID
func domain(of path: String) -> String {
	let name = (path as NSString).lastPathComponent.replacingOccurrences(of: ".plist", with: "")
	let domain = name.replacingOccurrences(of: #"\.[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}$"#, with: "", options: .regularExpression)
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

// the keys that changed, with dictionaries followed into, e.g. "AppleSymbolicHotKeys.64.enabled"
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
	for path in Set(paths.prefix(count)) where isPreferenceFile(path) {
		let contents = read(path)
		let found = changes(known[path] ?? [:], contents ?? [:])
		known[path] = contents
		guard !found.isEmpty else { continue }
		print("\(time.string(from: Date())) \(domain(of: path))")
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
