{ lib }:
# Turns a plan into shell. This is the only place commands are built and quoted. Writes and
# deletes run in plan order, then each notification once, then each restart once, then each
# `afterwards` command once.
#
# A failing step is reported and activation continues, so one setting macOS refuses doesn't
# stop the rest.
let
	q = lib.escapeShellArg;

	# the domain argument, quoted; "~/…" domains are paths in the home directory
	domain = key:
		if key.scope == "system" then q (if lib.hasPrefix "/" key.domain then key.domain else "/Library/Preferences/${key.domain}")
		else if lib.hasPrefix "~/" key.domain then ''"$HOME"/${q (lib.removePrefix "~/" key.domain)}''
		else q key.domain;

	# `defaults [-currentHost] <verb> <domain> [<key>] …`, quoted
	defaultsFor = verb: key: rest:
		lib.optional key.byHost "-currentHost"
		++ [ verb (domain key) ]
		++ map q (lib.optional (key.name != null) key.name ++ rest);

	plistType = key: value:
		if key.type != null then key.type
		else if lib.isBool value then "bool"
		else if lib.isInt value then "int"
		else if lib.isFloat value then "float"
		else if lib.isString value then "string"
		else if lib.isList value then "array"
		else if lib.isAttrs value then "dict"
		else throw "can't store ${builtins.toJSON value} in ${key.domain} ${key.name}";

	scalar = value:
		if lib.isBool value then lib.boolToString value
		else toString value;

	# a scalar inside an array or dictionary, with its own type flag; a nested array or
	# dictionary as a property list fragment, which defaults parses
	typed = value:
		if lib.isList value || lib.isAttrs value then [ (xml value) ]
		else [ "-${plistType { type = null; domain = "?"; name = "?"; } value}" (scalar value) ];

	xml = value:
		if lib.isBool value then (if value then "<true/>" else "<false/>")
		else if lib.isInt value then "<integer>${toString value}</integer>"
		else if lib.isFloat value then "<real>${toString value}</real>"
		else if lib.isString value then "<string>${lib.escapeXML value}</string>"
		else if lib.isList value then "<array>${lib.concatMapStrings xml value}</array>"
		else "<dict>${lib.concatStrings (lib.mapAttrsToList (k: v: "<key>${lib.escapeXML k}</key>${xml v}") value)}</dict>";

	# the arguments after the type flag
	plistValues = value:
		if lib.isList value then lib.concatMap typed value
		else if lib.isAttrs value then lib.concatLists (lib.mapAttrsToList (k: v: [ k ] ++ typed v) value)
		else [ (scalar value) ];

	defaults = args: "/usr/bin/defaults ${lib.concatStringsSep " " args}";

	orReport = command: "${command} || echo ${q "nix-plist-manager: failed: ${command}"} >&2";

	step = s:
		if s.op == "write" then
			orReport (defaults (defaultsFor "write" s.key ([ "-${plistType s.key s.value}" ] ++ plistValues s.value)))

		else if s.op == "delete" then
			# deleting a key that isn't there is fine
			"${defaults (defaultsFor "delete" s.key [])} 2>/dev/null || true"

		else if s.op == "writeFlags" then
			let
				read = defaults (defaultsFor "read" s.key []);
				write = defaults (defaultsFor "write" s.key [ "-int" ]);
			in
			''
				current=$(${read} 2>/dev/null || echo ${toString (s.absent or 0)})
				case "$current" in ""|*[!0-9-]*) current=0 ;; esac
				${orReport "${write} \"$(( (current & ~${toString s.mask}) | ${toString s.bits} ))\""}''

		else if s.op == "mergeDict" then
			orReport (defaults (defaultsFor "write" s.key ([ "-dict-add" ] ++ plistValues s.entries)))

		else if s.op == "setMembers" then
			# defaults can't edit an array in place; NSUserDefaults can read and write it whole
			if s.key.byHost || s.key.scope != "user" || lib.hasPrefix "~/" s.key.domain
			then throw "setMembers only supports plain user domains, not ${s.key.domain}"
			else
				let
					domainName = if s.key.domain == "NSGlobalDomain" then "NSGlobalDomain" else s.key.domain;
					script = lib.concatStrings [
						"ObjC.import('Foundation');"
						"var d = $.NSUserDefaults.alloc.initWithSuiteName(${builtins.toJSON domainName});"
						"var items = ObjC.deepUnwrap(d.arrayForKey(${builtins.toJSON s.key.name})) || [];"
						"var members = ${builtins.toJSON s.members};"
						"Object.keys(members).forEach(function (item) {"
						"  var at = items.indexOf(item);"
						"  if (members[item] && at < 0) items.push(item);"
						"  if (!members[item] && at >= 0) items.splice(at, 1);"
						"});"
						"d.setObjectForKey($(items), ${builtins.toJSON s.key.name});"
						"d.synchronize;"
					];
				in
				orReport "/usr/bin/osascript -l JavaScript -e ${q script} >/dev/null"

		else if s.op == "restore" then
			# clear the domain or key first: importing only adds and replaces keys
			lib.concatStringsSep "\n" [
				"${defaults (defaultsFor "delete" s.key [])} 2>/dev/null || true"
				(orReport (defaults (lib.optional s.key.byHost "-currentHost" ++ [ "import" (domain s.key) (q s.file) ])))
			]

		else if s.op == "run" then s.command

		else throw "unknown plan step ${s.op}";

	named = op: plan: lib.unique (map (s: s.${if op == "notify" then "name" else "process"}) (lib.filter (s: s.op == op) plan));
in
{
	script = plan:
		lib.concatStringsSep "\n" (
			map step (lib.filter (s: !(lib.elem s.op [ "notify" "restart" "afterwards" ])) plan)
			++ map (name: "/usr/bin/notifyutil -p ${q name} 2>/dev/null || true") (named "notify" plan)
			++ map (process:
				let
					discard = lib.any (s: s.op == "restart" && s.process == process && (s.discard or false)) plan;
				in
				"/usr/bin/killall ${lib.optionalString discard "-KILL "}${q process} 2>/dev/null || true"
			) (named "restart" plan)
			++ lib.unique (map (s: s.command) (lib.filter (s: s.op == "afterwards") plan))
		);
}
