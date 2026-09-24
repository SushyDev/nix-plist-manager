{ lib }:
let
	q = lib.escapeShellArg;

	domain = key:
		if key.scope == "system" then q (if lib.hasPrefix "/" key.domain then key.domain else "/Library/Preferences/${key.domain}")
		else if lib.hasPrefix "~/" key.domain then ''"$HOME"/${q (lib.removePrefix "~/" key.domain)}''
		else q key.domain;

	defaultsFor = verb: key: rest:
		lib.optional key.byHost "-currentHost"
		++ [ verb (domain key) ]
		++ map q (lib.optional (key.name != null) key.name ++ rest);

	plistType = value:
		if lib.isBool value then "bool"
		else if lib.isInt value then "int"
		else if lib.isFloat value then "float"
		else if lib.isString value then "string"
		else if lib.isList value then "array"
		else if lib.isAttrs value then "dict"
		else throw "can't store ${builtins.toJSON value} in a preference";

	scalar = value:
		if lib.isBool value then lib.boolToString value
		else toString value;

	typed = value:
		if lib.isList value || lib.isAttrs value then [ (xml value) ]
		else [ "-${plistType value}" (scalar value) ];

	xml = value:
		if lib.isBool value then (if value then "<true/>" else "<false/>")
		else if lib.isInt value then "<integer>${toString value}</integer>"
		else if lib.isFloat value then "<real>${toString value}</real>"
		else if lib.isString value then "<string>${lib.escapeXML value}</string>"
		else if lib.isList value then "<array>${lib.concatMapStrings xml value}</array>"
		else "<dict>${lib.concatStrings (lib.mapAttrsToList (k: v: "<key>${lib.escapeXML k}</key>${xml v}") value)}</dict>";

	plistValues = value:
		if lib.isList value then lib.concatMap typed value
		else if lib.isAttrs value then lib.concatLists (lib.mapAttrsToList (k: v: [ k ] ++ typed v) value)
		else [ (scalar value) ];

	defaults = args: "/usr/bin/defaults ${lib.concatStringsSep " " args}";

	# A refused step is reported without stopping the rest of the activation.
	orReport = command: "${command} || echo ${q "nix-plist-manager: failed: ${command}"} >&2";

	step = s:
		if s.op == "write" then
			orReport (defaults (defaultsFor "write" s.key ([ "-${if s.key.type != null then s.key.type else plistType s.value}" ] ++ plistValues s.value)))

		else if s.op == "delete" then
			"${defaults (defaultsFor "delete" s.key [])} 2>/dev/null || true"

		else if s.op == "writeFlags" then
			let
				read = defaults (defaultsFor "read" s.key []);
				write = defaults (defaultsFor "write" s.key [ "-int" ]);
			in
			''
				current=$(${read} 2>/dev/null || echo ${toString s.absent})
				case "$current" in ""|*[!0-9-]*) current=0 ;; esac
				${orReport "${write} \"$(( (current & ~${toString s.mask}) | ${toString s.bits} ))\""}''

		else if s.op == "mergeDict" then
			orReport (defaults (defaultsFor "write" s.key ([ "-dict-add" ] ++ plistValues s.entries)))

		# defaults can't edit an array in place
		else if s.op == "setMembers" then
			if s.key.byHost || s.key.scope != "user" || lib.hasPrefix "~/" s.key.domain
			then throw "setMembers only supports plain user domains, not ${s.key.domain}"
			else
				let
					script = lib.concatStrings [
						"ObjC.import('Foundation');"
						"var d = $.NSUserDefaults.alloc.initWithSuiteName(${builtins.toJSON s.key.domain});"
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
			lib.concatStringsSep "\n" [
				# import only adds and replaces keys
				"${defaults (defaultsFor "delete" s.key [])} 2>/dev/null || true"
				(orReport (defaults (lib.optional s.key.byHost "-currentHost" ++ [ "import" (domain s.key) (q s.file) ])))
			]

		else if s.op == "run" then s.command

		else throw "unknown plan step ${s.op}";

in
{
	script = plan:
		let
			ofOp = op: lib.filter (s: s.op == op) plan;
			restarts = ofOp "restart";
			discarded = process: lib.any (s: s.process == process && s.discard) restarts;
		in
		lib.concatStringsSep "\n" (
			map step (lib.filter (s: !(lib.elem s.op [ "notify" "restart" "afterwards" ])) plan)
			++ map (name: "/usr/bin/notifyutil -p ${q name} 2>/dev/null || true") (lib.unique (map (s: s.name) (ofOp "notify")))
			++ map (process: "/usr/bin/killall ${lib.optionalString (discarded process) "-KILL "}${q process} 2>/dev/null || true")
				(lib.unique (map (s: s.process) restarts))
			++ lib.unique (map (s: s.command) (ofOp "afterwards"))
		);
}
