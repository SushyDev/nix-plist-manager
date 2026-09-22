// ax — read and operate System Settings through the Accessibility API.
//
// Every element is addressed by the labels of its ancestors, so scripts can say
// "the switch labelled Magnification" instead of relying on positions.
//
// Usage:
//   ax dump [--depth N] [--sheet]        print the window's (or open sheet's) element tree as JSON lines
//   ax get <label>                       print the element's value as JSON
//   ax press <label>                     AXPress the element (buttons, checkboxes, radio buttons)
//   ax click <label>                     click the element's centre (for switches that ignore AXPress)
//   ax set <label> <value>               set AXValue (sliders, text fields)
//   ax items <label>                     list a pop-up button's menu items
//   ax pick <label> <item>               open a pop-up button and choose a menu item
//
// <label> matches an element's title, description, label or identifier (case-insensitive,
// whole string). "A > B" matches B inside an element labelled A, "B + C" an element labelled
// both B and C, and "AXRadioButton:B" only elements with that role.
//
// Requires Accessibility permission for the terminal that runs it.

import ApplicationServices
import AppKit
import Foundation

// AX_APP targets another app, e.g. com.apple.controlcenter to edit Control Center itself
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
	// SwiftUI rows often carry their label on a static text child instead of the control
	if let titleElement = attribute(element, kAXTitleUIElementAttribute) {
		result += [string(titleElement as! AXUIElement, kAXValueAttribute)].compactMap { $0 }
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

/// Press a pop-up button and return the menu it opens. Menus appear asynchronously, and a
/// menu from an earlier press can linger in the tree, so wait for one that wasn't there before.
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
	// Escape goes to the frontmost app, so make sure that's System Settings
	guard (try? bringToFront()) != nil else { return }
	for down in [true, false] {
		CGEvent(keyboardEventSource: nil, virtualKey: 53, keyDown: down)?.post(tap: .cghidEventTap)  // Escape
	}
	Thread.sleep(forTimeInterval: 0.2)
}

/// Bring System Settings to the front, so synthetic clicks and keys reach it. A background
/// process's `activate()` and setting AXFrontmost are both ignored while another app holds
/// focus; opening it through LaunchServices isn't.
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

/// Depth-first walk that yields each element with the labels of its ancestors.
func walk(_ element: AXUIElement, path: [String] = [], depth: Int = 0, maxDepth: Int = 60,
          visit: (AXUIElement, [String], Int) -> Bool) {
	if !visit(element, path, depth) || depth >= maxDepth { return }
	let own = labels(element).first
	for child in children(element) {
		walk(child, path: own.map { path + [$0] } ?? path, depth: depth + 1, maxDepth: maxDepth, visit: visit)
	}
}

/// The last part of a query: "[Role:]label[ + label…]", e.g. "AXRadioButton:Dark" or "Dark + Icon & widget style".
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
		if let role = role, string(element, kAXRoleAttribute) != role { return false }
		let own = labels(element).map { $0.lowercased() }
		return wanted.allSatisfy(own.contains)
	}
}

func find(_ query: String, in root: AXUIElement) throws -> AXUIElement {
	let parts = query.components(separatedBy: " > ").map { $0.trimmingCharacters(in: .whitespaces) }
	let selector = Selector(parts.last ?? "")
	let ancestorsWanted = parts.dropLast().map { $0.lowercased() }
	var matches: [AXUIElement] = []
	walk(root) { element, path, _ in
		guard selector.matches(element) else { return true }
		// every earlier part has to appear, in order, among the ancestors
		var ancestors = path.map { $0.lowercased() }[...]
		for part in ancestorsWanted {
			guard let index = ancestors.firstIndex(of: part) else { return true }
			ancestors = ancestors[(index + 1)...]
		}
		matches.append(element)
		return true
	}
	// prefer an actual control over the static text that labels it
	let controls = matches.filter { string($0, kAXRoleAttribute) != kAXStaticTextRole }
	guard let match = controls.first ?? matches.first else { throw Failure(description: "no element labelled '\(query)'") }
	if controls.count > 1 {
		FileHandle.standardError.write("warning: \(controls.count) elements labelled '\(query)', using the first\n".data(using: .utf8)!)
	}
	return match
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
		// with a sheet open (e.g. Hot Corners…), only its contents are of interest
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

	case "press":
		guard args.count == 2 else { throw Failure(description: "usage: ax press <label>") }
		let result = AXUIElementPerformAction(try find(args[1], in: window), kAXPressAction as CFString)
		guard result == .success else { throw Failure(description: "AXPress failed: \(result.rawValue)") }

	case "click":
		// some SwiftUI controls (switches) ignore AXPress, so click them like a person would
		guard args.count == 2 else { throw Failure(description: "usage: ax click <label>") }
		let element = try find(args[1], in: window)
		try bringToFront()
		AXUIElementPerformAction(window, kAXRaiseAction as CFString)
		// long panes put controls below the fold, and a click there would land on whatever is
		// on screen at that point (the Dock), so scroll the pane until the control is inside the window
		guard let windowBox = frame(of: window) else { throw Failure(description: "the window has no frame") }
		let visible = windowBox.intersection(NSScreen.screens.first.map { CGRect(origin: .zero, size: $0.frame.size) } ?? windowBox)
		var box = frame(of: element)
		// scroll events go to what's under the pointer: the column the control is in (the pane,
		// or the sidebar for sidebar items)
		let column = box.map { min(max($0.midX, visible.minX + 10), visible.maxX - 10) } ?? (visible.minX + visible.width * 0.7)
		let paneCenter = CGPoint(x: column, y: visible.midY)
		CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: paneCenter, mouseButton: .left)?
			.post(tap: .cghidEventTap)
		// a sidebar row that isn't built yet has no frame: scroll the sidebar until it exists
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

	case "step":
		// move a slider or stepper one step, as its arrow keys do: ax step <label> up|down
		guard args.count == 3, ["up", "down"].contains(args[2]) else { throw Failure(description: "usage: ax step <label> up|down") }
		let element = try find(args[1], in: window)
		let action = args[2] == "up" ? kAXIncrementAction : kAXDecrementAction
		let result = AXUIElementPerformAction(element, action as CFString)
		guard result == .success else { throw Failure(description: "\(action) failed: \(result.rawValue)") }

	case "items":
		guard args.count == 2 else { throw Failure(description: "usage: ax items <label>") }
		let menu = try openMenu(for: try find(args[1], in: window))
		var items: [String] = []
		walk(menu) { element, _, _ in
			// skip the variants a menu offers while a modifier key is held, e.g. "⌥⌘ Desktop"
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

do {
	try run(Array(CommandLine.arguments.dropFirst()))
} catch {
	FileHandle.standardError.write("ax: \(error)\n".data(using: .utf8)!)
	exit(1)
}
