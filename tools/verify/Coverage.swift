import Foundation

// pane → reason → titles
typealias Reasons = [String: [String: [String]]]

struct Coverage {
	var verified: [String: [String]]
	var todo: Reasons
	var notCovered: Reasons
	var notSettings: Reasons
}

let coveragePath = root.appendingPathComponent("coverage.json")

func loadCoverage() throws -> Coverage {
	let raw = try parseJSON(try Data(contentsOf: coveragePath)) as! [String: Any]
	return Coverage(
		verified: raw["verified"] as? [String: [String]] ?? [:], todo: raw["todo"] as? Reasons ?? [:],
		notCovered: raw["notCovered"] as? Reasons ?? [:], notSettings: raw["notSettings"] as? Reasons ?? [:])
}

func saveCoverage(_ coverage: Coverage) throws {
	let list = { (values: [String]) in "[\n" + values.sorted().map { "\t\t\t\(json($0))" }.joined(separator: ",\n") + "\n\t\t]" }
	let grouped = { (groups: Reasons) in
		groups.keys.sorted().map { pane in
			"\t\t\(json(pane)): {\n" + groups[pane]!.keys.sorted().map { "\t\t\t\(json($0)): \(json(groups[pane]![$0]!))" }.joined(separator: ",\n") + "\n\t\t}"
		}.joined(separator: ",\n")
	}
	let verified = coverage.verified.keys.sorted().filter { !coverage.verified[$0]!.isEmpty }
		.map { "\t\t\(json($0)): \(list(coverage.verified[$0]!))" }.joined(separator: ",\n")
	try """
	{
		"verified": {
	\(verified)
		},
		"todo": {
	\(grouped(coverage.todo))
		},
		"notCovered": {
	\(grouped(coverage.notCovered))
		},
		"notSettings": {
	\(grouped(coverage.notSettings))
		}
	}

	""".write(to: coveragePath, atomically: true, encoding: .utf8)
}
