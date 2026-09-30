import Foundation

let usage = """
nix run .#verify -- <command>: check options against System Settings and look into it; needs Accessibility permission.

  check [--pane P] [--option O] [--batch] [--skip regex] [--only-unverified] [--side-effects]
  defaults [--pane P] [--option O] [--batch] [--skip regex] [--missing] [--side-effects]
  shown <option>…                    the values System Settings shows for these options, as JSON
  discover <pane> [--open control]…  the settings a page shows
  gaps [--pane name]                 what System Settings shows that coverage doesn't account for
  observe <pane> [--open control]… <ax command…>   operate a control and print the keys it changes
  watch [<domain part>…]             print each preference key that changes; -g is the global domain
  ax <command…>                      dump [--depth N] [--sheet] | get|press|click|items <label> | values <label>… |
                                     set <label> <value> | pick <label> <item>
  wallpapers                         print the catalog of wallpapers macOS comes with

<pane> is a sidebar identifier such as com.apple.settings.appearance. A setting's spec:

  verify = {
    pane = "com.apple.settings.appearance";
    open = [ "Hot Corners…" ];
    operate = [ "click" "TintWindowBackgroundToggle" ];
    expect = {
      true = { TintWindowBackgroundToggle = 1; };
      false = { TintWindowBackgroundToggle = 0; };
    };
  };
"""

func fail(_ message: String) -> Never {
	FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
	exit(2)
}

// Flags with a value, flags without one, and what's left over.
func parse(_ args: [String], values: Set<String>, flags: Set<String>) -> (values: [String: [String]], flags: Set<String>, rest: [String]) {
	var found: [String: [String]] = [:], set = Set<String>(), rest: [String] = []
	var index = 0
	while index < args.count {
		let arg = args[index]
		if values.contains(arg), index + 1 < args.count {
			found[arg, default: []].append(args[index + 1])
			index += 1
		} else if flags.contains(arg) {
			set.insert(arg)
		} else if arg.hasPrefix("--") && rest.isEmpty {
			fail("unknown option \(arg)\n\n\(usage)")
		} else {
			rest.append(arg)
		}
		index += 1
	}
	return (found, set, rest)
}

func selection(_ args: [String], extra: Set<String>) -> (Selection, Set<String>) {
	let (values, flags, rest) = parse(args, values: ["--pane", "--option", "--skip"], flags: Set(["--batch", "--side-effects"]).union(extra))
	if !rest.isEmpty { fail(usage) }
	var selection = Selection()
	selection.pane = values["--pane"]?.last
	selection.option = values["--option"]?.last
	selection.skip = values["--skip"]?.last
	selection.batch = flags.contains("--batch")
	selection.sideEffects = flags.contains("--side-effects")
	return (selection, flags)
}

let arguments = Array(CommandLine.arguments.dropFirst())
let rest = Array(arguments.dropFirst())

do {
	switch arguments.first {
	case "check":
		var (chosen, flags) = selection(rest, extra: ["--only-unverified"])
		chosen.onlyUnverified = flags.contains("--only-unverified")
		exit(try runCheck(chosen))
	case "defaults":
		var (chosen, flags) = selection(rest, extra: ["--missing"])
		chosen.defaults = true
		chosen.onlyUnverified = flags.contains("--missing")
		try runDefaults(chosen, missing: flags.contains("--missing"))
	case "shown":
		if rest.isEmpty { fail(usage) }
		try runShown(rest)
	case "discover":
		let (values, _, pane) = parse(rest, values: ["--open"], flags: [])
		if pane.count != 1 { fail(usage) }
		try runDiscover(pane[0], open: values["--open"] ?? [])
	case "gaps":
		let (values, _, extra) = parse(rest, values: ["--pane"], flags: [])
		if !extra.isEmpty { fail(usage) }
		try runGaps(pane: values["--pane"]?.last)
	case "observe":
		let (values, _, positional) = parse(rest, values: ["--open"], flags: [])
		if positional.count < 2 { fail(usage) }
		try observe(positional[0], open: values["--open"] ?? [], command: Array(positional.dropFirst()))
	case "watch":
		watch(rest)
	case "ax":
		let output = try ax(rest)
		if !output.isEmpty { print(output) }
	case "wallpapers":
		try wallpapers()
	default:
		fail(usage)
	}
} catch {
	FileHandle.standardError.write("verify: \(error)\n".data(using: .utf8)!)
	exit(1)
}
