// ax dump [--depth N] [--sheet] | get|press|click|items <label> | set <label> <value> | pick <label> <item>
// Labels: "A > B" (B inside A), "B + C" (both labels), "AXRole:B" (by role), "B#2" (second match).

import ApplicationServices
import AppKit
import Foundation

let settingsBundleID = ProcessInfo.processInfo.environment["AX_APP"] ?? "com.apple.systempreferences"

struct Failure: Error, CustomStringConvertible {
	let description: String
}

func attribute(_ element: AXUIElement, _ name: String) -> AnyObject? {
	var value: AnyObject?
	guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
	return value
}

func string(_ element: AXUIElement, _ name: String) -> String? {
	(attribute(element, name) as? String).flatMap { $0.isEmpty ? nil : $0 }
}

func children(_ element: AXUIElement) -> [AXUIElement] {
	(attribute(element, kAXChildrenAttribute) as? [AXUIElement]) ?? []
}

func labels(_ element: AXUIElement) -> [String] {
	var result = [kAXTitleAttribute, kAXDescriptionAttribute, kAXIdentifierAttribute, "AXLabel"]
		.compactMap { string(element, $0) }
	// SwiftUI rows often label a control through a static text child
	if let titleElement = attribute(element, kAXTitleUIElementAttribute) {
		result += [string(titleElement as! AXUIElement, kAXValueAttribute)].compactMap { $0 }
	}
	// list rows put an unlabeled checkbox next to the row's text
	if result.isEmpty, string(element, kAXRoleAttribute) == kAXCheckBoxRole,
	   let cell = attribute(element, kAXParentAttribute) {
		result += children(cell as! AXUIElement)
			.filter { string($0, kAXRoleAttribute) == kAXStaticTextRole }
			.compactMap { string($0, kAXValueAttribute) }
	}
	return result
}

func jsonValue(_ value: AnyObject?) -> Any {
	switch value {
	case let number as NSNumber: return number
	case let text as String: return text
	case nil: return NSNull()
	default: return String(describing: value!)
	}
}

func settingsApp() throws -> AXUIElement {
	guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: settingsBundleID).first else {
		throw Failure(description: "System Settings is not running")
	}
	let appElement = AXUIElementCreateApplication(app.processIdentifier)
	AXUIElementSetMessagingTimeout(appElement, 5)
	return appElement
}

func menus() throws -> [AXUIElement] {
	var found: [AXUIElement] = []
	walk(try settingsApp(), maxDepth: 12) { element, _, _ in
		if string(element, kAXRoleAttribute) == kAXMenuRole { found.append(element) }
		return true
	}
	return found
}

// a menu from an earlier press can linger in the tree
func openMenu(for popup: AXUIElement) throws -> AXUIElement {
	let before = try menus()
	guard AXUIElementPerformAction(popup, kAXPressAction as CFString) == .success else {
		throw Failure(description: "could not open the pop-up")
	}
	for _ in 0..<20 {
		Thread.sleep(forTimeInterval: 0.1)
		if let menu = try menus().first(where: { new in !before.contains(where: { CFEqual($0, new) }) }) {
			return menu
		}
	}
	throw Failure(description: "no menu opened")
}

func closeMenus() {
	// Escape goes to the frontmost app
	guard (try? bringToFront()) != nil else { return }
	for down in [true, false] {
		CGEvent(keyboardEventSource: nil, virtualKey: 53, keyDown: down)?.post(tap: .cghidEventTap)  // Escape
	}
	Thread.sleep(forTimeInterval: 0.2)
}

// activate() and AXFrontmost are ignored while another app has focus; LaunchServices isn't
func bringToFront() throws {
	let isFront = { NSWorkspace.shared.frontmostApplication?.bundleIdentifier == settingsBundleID }
	if isFront() { return }
	let open = Process()
	open.executableURL = URL(fileURLWithPath: "/usr/bin/open")
	open.arguments = ["-b", settingsBundleID]
	try open.run()
	open.waitUntilExit()
	for _ in 0..<30 {
		if isFront() { return }
		Thread.sleep(forTimeInterval: 0.1)
	}
	throw Failure(description: "couldn't bring System Settings to the front")
}

func settingsWindow() throws -> AXUIElement {
	let appElement = try settingsApp()
	if ProcessInfo.processInfo.environment["AX_APP"] != nil { return appElement }
	guard let window = (attribute(appElement, kAXWindowsAttribute) as? [AXUIElement])?.first else {
		throw Failure(description: "System Settings has no window")
	}
	return window
}

struct Node {
	let element: AXUIElement
	let role: String?
	let labels: [String]
	let children: [AXUIElement]
}

let nodeAttributes = [kAXRoleAttribute, kAXTitleAttribute, kAXDescriptionAttribute, kAXIdentifierAttribute, "AXLabel",
	kAXTitleUIElementAttribute, kAXChildrenAttribute] as CFArray

// one round trip per element instead of one per attribute
func node(_ element: AXUIElement) -> Node {
	var fetched: CFArray?
	AXUIElementCopyMultipleAttributeValues(element, nodeAttributes, AXCopyMultipleAttributeOptions(rawValue: 0), &fetched)
	let values = (fetched as? [AnyObject]) ?? []
	let value = { (index: Int) -> AnyObject? in
		guard index < values.count, CFGetTypeID(values[index]) != AXValueGetTypeID() else { return nil }
		return values[index]
	}
	let role = value(0) as? String
	var own = (1...4).compactMap { (value($0) as? String).flatMap { $0.isEmpty ? nil : $0 } }
	if let title = value(5), CFGetTypeID(title) == AXUIElementGetTypeID() {
		own += [string(title as! AXUIElement, kAXValueAttribute)].compactMap { $0 }
	}
	if own.isEmpty, role == kAXCheckBoxRole {
		own = labels(element)
	}
	return Node(element: element, role: role, labels: own, children: (value(6) as? [AXUIElement]) ?? [])
}

// visit returns false to stop the whole walk
func walkNodes(_ element: AXUIElement, path: [String] = [], depth: Int = 0, maxDepth: Int = 60,
               visit: (Node, [String]) -> Bool) -> Bool {
	let current = node(element)
	if !visit(current, path) { return false }
	if depth >= maxDepth { return true }
	let childPath = current.labels.first.map { path + [$0] } ?? path
	for child in current.children {
		if !walkNodes(child, path: childPath, depth: depth + 1, maxDepth: maxDepth, visit: visit) { return false }
	}
	return true
}

func walk(_ element: AXUIElement, path: [String] = [], depth: Int = 0, maxDepth: Int = 60,
          visit: (AXUIElement, [String], Int) -> Bool) {
	if !visit(element, path, depth) || depth >= maxDepth { return }
	let own = labels(element).first
	for child in children(element) {
		walk(child, path: own.map { path + [$0] } ?? path, depth: depth + 1, maxDepth: maxDepth, visit: visit)
	}
}

struct Selector {
	var role: String?
	var wanted: [String]

	init(_ text: String) {
		var labels = text.components(separatedBy: " + ").map { $0.trimmingCharacters(in: .whitespaces) }
		if let colon = labels[0].firstIndex(of: ":"), labels[0].hasPrefix("AX") {
			role = String(labels[0][..<colon])
			labels[0] = String(labels[0][labels[0].index(after: colon)...])
		}
		wanted = labels.map { $0.lowercased() }
	}

	func matches(_ element: AXUIElement) -> Bool {
		matches(role: string(element, kAXRoleAttribute), labels: labels(element))
	}

	func matches(role elementRole: String?, labels: [String]) -> Bool {
		if let role = role, elementRole != role { return false }
		if role != nil && wanted == [""] { return true }
		let own = labels.map { $0.lowercased() }
		return wanted.allSatisfy(own.contains)
	}
}

struct Query {
	let text: String
	let selector: Selector
	let ancestors: [String]
	let nth: Int?

	init(_ fullQuery: String) {
		var query = fullQuery, nth: Int? = nil
		if let hash = fullQuery.lastIndex(of: "#"), let n = Int(fullQuery[fullQuery.index(after: hash)...]), n > 0 {
			query = String(fullQuery[..<hash])
			nth = n
		}
		let parts = query.components(separatedBy: " > ").map { $0.trimmingCharacters(in: .whitespaces) }
		text = query
		selector = Selector(parts.last ?? "")
		ancestors = parts.dropLast().map { $0.lowercased() }
		self.nth = nth
	}

	func matches(_ node: Node, path: [String]) -> Bool {
		guard selector.matches(role: node.role, labels: node.labels) else { return false }
		var remaining = path.map { $0.lowercased() }[...]
		for part in ancestors {
			guard let index = remaining.firstIndex(of: part) else { return false }
			remaining = remaining[(index + 1)...]
		}
		return true
	}

	func pick(_ matches: [AXUIElement]) throws -> AXUIElement {
		let controls = matches.filter { string($0, kAXRoleAttribute) != kAXStaticTextRole }
		if let nth = nth {
			guard nth <= controls.count else { throw Failure(description: "only \(controls.count) elements labeled '\(text)'") }
			return controls[nth - 1]
		}
		guard let match = controls.first ?? matches.first else { throw Failure(description: "no element labeled '\(text)'") }
		return match
	}
}

// one walk of the tree for all queries
func findAll(_ queries: [String], in root: AXUIElement) -> [String: Result<AXUIElement, Error>] {
	let parsed = queries.map(Query.init)
	var matches = Array(repeating: [AXUIElement](), count: parsed.count)
	var found = Array(repeating: false, count: parsed.count)
	_ = walkNodes(root) { node, path in
		for (index, query) in parsed.enumerated() where query.matches(node, path: path) {
			matches[index].append(node.element)
			// a control settles it, unless a later match is wanted ("#2")
			if query.nth == nil && node.role != kAXStaticTextRole { found[index] = true }
		}
		return !found.allSatisfy { $0 }
	}
	var results: [String: Result<AXUIElement, Error>] = [:]
	for (index, query) in parsed.enumerated() {
		results[queries[index]] = Result { try query.pick(matches[index]) }
	}
	return results
}

func find(_ query: String, in root: AXUIElement) throws -> AXUIElement {
	try findAll([query], in: root)[query]!.get()
}

func frame(of element: AXUIElement) -> CGRect? {
	var point = CGPoint.zero, size = CGSize.zero
	guard let position = attribute(element, kAXPositionAttribute), let extent = attribute(element, kAXSizeAttribute),
	      AXValueGetValue(position as! AXValue, .cgPoint, &point), AXValueGetValue(extent as! AXValue, .cgSize, &size)
	else { return nil }
	return CGRect(origin: point, size: size)
}

func describe(_ element: AXUIElement, path: [String], depth: Int) -> [String: Any] {
	var entry: [String: Any] = [
		"depth": depth,
		"role": string(element, kAXRoleAttribute) ?? "",
		"path": path,
	]
	if let subrole = string(element, kAXSubroleAttribute) { entry["subrole"] = subrole }
	let own = labels(element)
	if !own.isEmpty { entry["labels"] = own }
	if let value = attribute(element, kAXValueAttribute) { entry["value"] = jsonValue(value) }
	if let enabled = attribute(element, kAXEnabledAttribute) as? Bool, !enabled { entry["enabled"] = false }
	if let selected = attribute(element, kAXSelectedAttribute) as? Bool, selected { entry["selected"] = true }
	return entry
}

func printJSON(_ object: Any) {
	let data = try! JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .fragmentsAllowed])
	print(String(data: data, encoding: .utf8)!)
}

func run(_ args: [String]) throws {
	guard AXIsProcessTrusted() else { throw Failure(description: "Accessibility permission is not granted") }
	guard let command = args.first else { throw Failure(description: "usage: ax dump|get|press|set|pick …") }
	let window = try settingsWindow()

	switch command {
	case "dump":
		let maxDepth = args.count > 2 && args[1] == "--depth" ? Int(args[2]) ?? 60 : 60
		var root = window
		if args.contains("--sheet") {
			guard let sheet = children(window).first(where: { string($0, kAXRoleAttribute) == kAXSheetRole }) else {
				throw Failure(description: "no sheet is open")
			}
			root = sheet
		}
		walk(root, maxDepth: maxDepth) { element, path, depth in
			printJSON(describe(element, path: path, depth: depth))
			return true
		}

	case "get":
		guard args.count == 2 else { throw Failure(description: "usage: ax get <label>") }
		let element = try find(args[1], in: window)
		var entry = describe(element, path: [], depth: 0)
		var actions: CFArray?
		if AXUIElementCopyActionNames(element, &actions) == .success { entry["actions"] = actions as? [String] ?? [] }
		if let frame = frame(of: element) { entry["frame"] = [frame.minX, frame.minY, frame.width, frame.height] }
		printJSON(entry)

	case "values":
		var result: [String: Any] = [:]
		for (query, found) in findAll(Array(args.dropFirst()), in: window) {
			switch found {
			case .success(let element): result[query] = describe(element, path: [], depth: 0)
			case .failure(let error): result[query] = ["error": "\(error)"]
			}
		}
		printJSON(result)

	case "press":
		guard args.count == 2 else { throw Failure(description: "usage: ax press <label>") }
		let result = AXUIElementPerformAction(try find(args[1], in: window), kAXPressAction as CFString)
		guard result == .success else { throw Failure(description: "AXPress failed: \(result.rawValue)") }

	case "click":
		// SwiftUI switches ignore AXPress
		guard args.count == 2 else { throw Failure(description: "usage: ax click <label>") }
		let element = try find(args[1], in: window)
		try bringToFront()
		AXUIElementPerformAction(window, kAXRaiseAction as CFString)
		// a click below the fold would land on whatever is on screen there, such as the Dock
		guard let windowBox = frame(of: window) else { throw Failure(description: "the window has no frame") }
		let visible = windowBox.intersection(NSScreen.screens.first.map { CGRect(origin: .zero, size: $0.frame.size) } ?? windowBox)
		var box = frame(of: element)
		// scroll events go to the column under the pointer
		let column = box.map { min(max($0.midX, visible.minX + 10), visible.maxX - 10) } ?? (visible.minX + visible.width * 0.7)
		let paneCenter = CGPoint(x: column, y: visible.midY)
		CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: paneCenter, mouseButton: .left)?
			.post(tap: .cghidEventTap)
		// a sidebar row that isn't built yet has no frame
		if box == nil {
			CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: CGPoint(x: visible.minX + 110, y: visible.midY), mouseButton: .left)?
				.post(tap: .cghidEventTap)
			for _ in 0..<40 where box == nil {
				CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: -3, wheel2: 0, wheel3: 0)?
					.post(tap: .cghidEventTap)
				Thread.sleep(forTimeInterval: 0.08)
				box = frame(of: try find(args[1], in: window))
			}
		}
		for _ in 0..<40 {
			guard let current = box, !visible.insetBy(dx: 0, dy: 20).contains(current) else { break }
			let lines: Int32 = current.midY > visible.midY ? -3 : 3
			CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: lines, wheel2: 0, wheel3: 0)?
				.post(tap: .cghidEventTap)
			Thread.sleep(forTimeInterval: 0.08)
			box = frame(of: element)
		}
		guard let box = box, visible.contains(box) else {
			throw Failure(description: "'\(args[1])' can't be scrolled into view, not clicking")
		}
		let point = CGPoint(x: box.midX, y: box.midY)
		for type in [CGEventType.mouseMoved, .leftMouseDown, .leftMouseUp] {
			CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: .left)?.post(tap: .cghidEventTap)
			Thread.sleep(forTimeInterval: 0.05)
		}

	case "set":
		guard args.count == 3 else { throw Failure(description: "usage: ax set <label> <value>") }
		let element = try find(args[1], in: window)
		let value: CFTypeRef = Double(args[2]).map { $0 as NSNumber } ?? args[2] as NSString
		let result = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, value)
		guard result == .success else { throw Failure(description: "setting AXValue failed: \(result.rawValue)") }

	case "items":
		guard args.count == 2 else { throw Failure(description: "usage: ax items <label>") }
		let menu = try openMenu(for: try find(args[1], in: window))
		var items: [String] = []
		walk(menu) { element, _, _ in
			// skip the variants shown while a modifier key is held, e.g. "⌥⌘ Desktop"
			if string(element, kAXRoleAttribute) == kAXMenuItemRole, let title = labels(element).first,
			   !title.hasPrefix("⌘"), !title.hasPrefix("⌥"), !title.hasPrefix("⌃"), !title.hasPrefix("⇧") {
				items.append(title.trimmingCharacters(in: .whitespaces))
			}
			return true
		}
		closeMenus()
		printJSON(items)

	case "pick":
		guard args.count == 3 else { throw Failure(description: "usage: ax pick <label> <item>") }
		let menu = try openMenu(for: try find(args[1], in: window))
		var item: AXUIElement?
		walk(menu) { element, _, _ in
			if item == nil, string(element, kAXRoleAttribute) == kAXMenuItemRole,
			   labels(element).contains(where: {
				   $0.trimmingCharacters(in: .whitespaces).lowercased() == args[2].trimmingCharacters(in: .whitespaces).lowercased()
			   }) {
				item = element
			}
			return item == nil
		}
		guard let menuItem = item else {
			closeMenus()
			throw Failure(description: "no menu item '\(args[2])'")
		}
		if let enabled = attribute(menuItem, kAXEnabledAttribute) as? Bool, !enabled {
			closeMenus()
			throw Failure(description: "menu item '\(args[2])' is disabled")
		}
		AXUIElementPerformAction(menuItem, kAXPressAction as CFString)

	default:
		throw Failure(description: "unknown command \(command)")
	}
}

// ax serve: one command per line as a JSON array, each answered by its output and an "\u{4} ok" or
// "\u{4} <error>" line, so callers skip starting a process per command
if CommandLine.arguments.dropFirst().first == "serve" {
	while let line = readLine() {
		let args = (try? JSONSerialization.jsonObject(with: Data(line.utf8))) as? [String] ?? []
		do {
			try run(args)
			print("\u{4} ok")
		} catch {
			print("\u{4} \(error)")
		}
		fflush(stdout)
	}
	exit(0)
}

do {
	try run(Array(CommandLine.arguments.dropFirst()))
} catch {
	FileHandle.standardError.write("ax: \(error)\n".data(using: .utf8)!)
	exit(1)
}
