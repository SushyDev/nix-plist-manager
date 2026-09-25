{ lib }:
let
	q = lib.escapeShellArg;

	# a script in this directory, given its input as JSON
	script = name: input: "/usr/bin/osascript -l JavaScript ${./. + "/${name}.js"}${lib.optionalString (input != null) " ${q (builtins.toJSON input)}"}";
	quietly = name: input: "${script name input} >/dev/null";
in
{
	appearance = { automatic, dark ? false }: quietly "appearance" { inherit automatic dark; };

	coreBrightness = client: method: arguments: quietly "core-brightness" { inherit client method arguments; };

	recentItems = amount: quietly "recent-items" amount;

	inputSources = ids: quietly "input-sources" ids;
	enabledInputSources = script "input-sources" null;

	setMembers = domain: key: members: quietly "set-members" { inherit domain key members; };

	wallpaper = wanted: quietly "wallpaper" wanted;

	pmsetValue = source: key:
		"/usr/bin/pmset -g custom | /usr/bin/awk ${q "$0 == \"${source}:\" { found = 1; next } /^[^ ]/ { found = 0 } found && $1 == \"${key}\" { print $2 }"}";
}
