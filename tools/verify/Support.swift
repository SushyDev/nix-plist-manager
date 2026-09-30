import Foundation

struct Failure: Error, CustomStringConvertible {
	let description: String
	init(_ description: String) { self.description = description }
}

let environment = ProcessInfo.processInfo.environment
let root = URL(fileURLWithPath: environment["NIX_PLIST_MANAGER_ROOT"] ?? FileManager.default.currentDirectoryPath)
let cache = URL(fileURLWithPath: environment["XDG_CACHE_HOME"] ?? NSHomeDirectory() + "/.cache").appendingPathComponent("nix-plist-manager")

func say(_ line: String) {
	print(line)
	fflush(stdout)
}

func pause(_ seconds: Double) {
	Thread.sleep(forTimeInterval: seconds)
}

// Runs a command, capturing what it prints and its errors.
@discardableResult
func capture(_ argv: [String]) -> (status: Int32, output: Data, errors: String) {
	let process = Process()
	process.executableURL = URL(fileURLWithPath: argv[0].hasPrefix("/") ? argv[0] : "/usr/bin/env")
	process.arguments = argv[0].hasPrefix("/") ? Array(argv.dropFirst()) : argv
	let output = Pipe(), errors = Pipe()
	process.standardOutput = output
	process.standardError = errors
	do { try process.run() } catch { return (127, Data(), "\(error)") }
	var errorData = Data()
	let reading = Thread { errorData = errors.fileHandleForReading.readDataToEndOfFile() }
	reading.start()
	let data = output.fileHandleForReading.readDataToEndOfFile()
	process.waitUntilExit()
	while !reading.isFinished { Thread.sleep(forTimeInterval: 0.01) }
	return (process.terminationStatus, data, String(decoding: errorData, as: UTF8.self))
}

// Runs a command with its output shown.
@discardableResult
func execute(_ argv: [String]) -> Int32 {
	let process = Process()
	process.executableURL = URL(fileURLWithPath: argv[0].hasPrefix("/") ? argv[0] : "/usr/bin/env")
	process.arguments = argv[0].hasPrefix("/") ? Array(argv.dropFirst()) : argv
	do { try process.run() } catch { return 127 }
	process.waitUntilExit()
	return process.terminationStatus
}

func text(_ data: Data) -> String {
	String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
}

func matches(_ pattern: String, _ text: String, options: NSRegularExpression.Options = []) -> Bool {
	(try! NSRegularExpression(pattern: pattern, options: options)).firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
}

func replacing(_ pattern: String, in text: String, with template: String) -> String {
	(try! NSRegularExpression(pattern: pattern)).stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: template)
}

func unique<T: Hashable>(_ items: [T]) -> [T] {
	var seen = Set<T>()
	return items.filter { seen.insert($0).inserted }
}

// check() until it's true or the time is up; returns its last result.
func poll<T>(_ timeout: Double, _ check: () -> T?) -> T? {
	let deadline = Date().addingTimeInterval(timeout)
	while true {
		if let result = check() { return result }
		if Date() > deadline { return nil }
		pause(0.2)
	}
}

@discardableResult
func waitUntil<T>(_ what: String, timeout: Double = 15, _ attempt: () throws -> T) throws -> T {
	let deadline = Date().addingTimeInterval(timeout)
	while true {
		do { return try attempt() } catch {
			if Date() > deadline { throw Failure("timed out waiting for \(what)") }
			pause(0.15)
		}
	}
}

func isBool(_ value: Any?) -> Bool {
	guard let number = value as? NSNumber else { return false }
	return CFGetTypeID(number) == CFBooleanGetTypeID()
}

func truthy(_ value: Any?) -> Bool {
	switch value {
	case nil, is NSNull: return false
	case let number as NSNumber: return number.doubleValue != 0
	case let string as String: return !string.isEmpty
	case let array as [Any]: return !array.isEmpty
	case let dictionary as [String: Any]: return !dictionary.isEmpty
	default: return true
	}
}

func same(_ a: Any?, _ b: Any?) -> Bool {
	switch (a, b) {
	case (nil, nil): return true
	case (nil, _), (_, nil): return false
	default: return (a as AnyObject).isEqual(b)
	}
}

func parseJSON(_ data: Data) throws -> Any {
	try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
}

// JSON the way Python's json.dumps writes it: ", " and ": " between items, sorted keys, text as is.
func json(_ value: Any?, indent: String? = nil, level: Int = 0) -> String {
	let inner = indent.map { "\n" + String(repeating: $0, count: level + 1) }
	let outer = indent.map { "\n" + String(repeating: $0, count: level) } ?? ""
	let separator = indent == nil ? ", " : ","
	switch value {
	case nil, is NSNull: return "null"
	case let number as NSNumber:
		if isBool(number) { return number.boolValue ? "true" : "false" }
		if CFNumberIsFloatType(number) {
			let double = number.doubleValue
			return double == double.rounded() && abs(double) < 1e16 ? String(format: "%.1f", double) : "\(double)"
		}
		return "\(number.int64Value)"
	case let string as String: return quote(string)
	case let array as [Any]:
		if array.isEmpty { return "[]" }
		return "[" + array.map { (inner ?? "") + json($0, indent: indent, level: level + 1) }.joined(separator: separator) + outer + "]"
	case let dictionary as [String: Any]:
		if dictionary.isEmpty { return "{}" }
		return "{" + dictionary.keys.sorted().map { (inner ?? "") + quote($0) + ": " + json(dictionary[$0], indent: indent, level: level + 1) }
			.joined(separator: separator) + outer + "}"
	default: return quote("\(value!)")
	}
}

func quote(_ string: String) -> String {
	var result = "\""
	for scalar in string.unicodeScalars {
		switch scalar {
		case "\"": result += "\\\""
		case "\\": result += "\\\\"
		case "\n": result += "\\n"
		case "\r": result += "\\r"
		case "\t": result += "\\t"
		case "\u{8}": result += "\\b"
		case "\u{c}": result += "\\f"
		case _ where scalar.value < 0x20: result += String(format: "\\u%04x", scalar.value)
		default: result.unicodeScalars.append(scalar)
		}
	}
	return result + "\""
}

// A value as a stable key, e.g. to look up the command for an option's value.
func canonical(_ value: Any?) -> String {
	json(value)
}
