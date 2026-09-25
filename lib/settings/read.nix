{ lib, module, render }:
let
	keyId = key: "${key.domain}|${lib.boolToString key.byHost}|${key.scope}";

	isNumber = value: lib.isInt value || lib.isFloat value;
	truthy = value: value != false && value != 0 && value != null;
	integer = value: if lib.isFloat value then builtins.floor value else value;

	same = actual: expected:
		if actual == null then false
		else if lib.isBool expected || lib.isBool actual then
			!(lib.isString actual || lib.isAttrs actual || lib.isList actual) && truthy actual == truthy expected
		else if isNumber expected && isNumber actual then
			(if actual > expected then actual - expected else expected - actual) < 1.0e-6
		else if lib.isAttrs expected && lib.isAttrs actual then
			lib.attrNames expected == lib.attrNames actual && lib.all (name: same actual.${name} expected.${name}) (lib.attrNames expected)
		else if lib.isList expected && lib.isList actual then
			lib.length expected == lib.length actual && lib.all lib.id (lib.zipListsWith same actual expected)
		else actual == expected;

	opMatches = get: op:
		let
			stored = get op.key;
		in
		if op.op == "write" then same stored op.value
		else if op.op == "delete" then stored == null
		else if op.op == "setMembers" then
			lib.all (item: lib.elem item (if lib.isList stored then stored else []) == op.members.${item}) (lib.attrNames op.members)
		else if op.op == "writeFlags" then
			builtins.bitAnd (integer (if stored == null then op.absent else stored)) op.mask == op.bits
		else if op.op == "mergeDict" then
			let
				entries = if lib.isAttrs stored then stored else {};
			in
			# an entry that is only switched off matches one that isn't there
			lib.all (name: same (entries.${name} or null) op.entries.${name} || (!(entries ? ${name}) && op.entries.${name} == { enabled = false; }))
				(lib.attrNames op.entries)
		else false;

	appliedThroughCommand = setting: lib.any (op: op.op == "run") (setting.plan (lib.head setting.codec.examples));

	fromChoices = setting: get:
		let
			opsOf = value: lib.filter (op: op ? key) (setting.codec.encode setting.keys value);
			matching = lib.filter (value: opsOf value != [] && lib.all (opMatches get) (opsOf value)) setting.codec.examples;
			writes = value: lib.count (op: op.op != "delete") (opsOf value);
		in
		if matching == [] then null else lib.head (lib.sort (a: b: writes a > writes b) matching);

	fromOutput = setting: output:
		let
			values = setting.reads.values or null;
			name = lib.findFirst (name: toString values.${name} == output.raw) null (lib.attrNames values);
		in
		if output == null || output.raw == "" then null
		else if values != null then (if name == null then null else setting.codec.fromName name)
		else if setting.reads ? parse then setting.reads.parse output.json
		else if setting.codec.kind == "string" then output.raw
		else output.json or output.raw;

	# a value written by deleting every key is what macOS falls back to
	codecDefault = setting:
		let
			keyOps = value: lib.filter (op: op ? key) (setting.codec.encode setting.keys value);
		in
		lib.findFirst (value: keyOps value != [] && lib.all (op: op.op == "delete") (keyOps value)) null
			(if lib.elem setting.codec.kind [ "bool" "enum" ] then setting.codec.examples else []);

	isDefault = state: option: setting: value:
		let
			default = state.defaults.${option} or (codecDefault setting);
			encode = setting.codec.encode setting.keys;
		in
		default != null && setting.codec.kind != "snapshot" && setting.option.type.check default && encode default == encode value;

	valueOf = state: option: setting:
		let
			get = key: if key.name == null then null else (state.domains.${keyId key} or {}).${key.name} or null;
			readers = [
				(_: if setting.reads != null then fromOutput setting (state.reads.${option} or null) else null)
				(_: if setting.codec ? decode then setting.codec.decode setting.keys get else null)
				(_: if lib.elem setting.codec.kind [ "bool" "enum" ] && !(appliedThroughCommand setting) then fromChoices setting get else null)
				(_: state.ui.${option} or null)
			];
			valid = value: value != null && setting.option.type.check value;
		in
		lib.findFirst valid null (map (reader: reader null) readers);
	simulate = ops:
		let
			apply = domains: op:
				let
					id = keyId op.key;
					stored = (domains.${id} or {}).${op.key.name} or null;
					set = value: domains // { ${id} = (domains.${id} or {}) // { ${op.key.name} = value; }; };
				in
				if op.op == "write" then set op.value
				else if op.op == "delete" then domains // { ${id} = removeAttrs (domains.${id} or {}) [ op.key.name ]; }
				else if op.op == "mergeDict" then set ((if lib.isAttrs stored then stored else {}) // op.entries)
				else if op.op == "setMembers" then
					set (lib.filter (item: op.members.${item} or true) (if lib.isList stored then stored else [])
						++ lib.filter (item: op.members.${item} && !(lib.elem item (if lib.isList stored then stored else []))) (lib.attrNames op.members))
				else if op.op == "writeFlags" then
					set (builtins.bitOr (builtins.bitAnd (if stored == null then op.absent else stored) (builtins.bitXor (-1) op.mask)) op.bits)
				else domains;
		in
		{ domains = lib.foldl' apply {} (lib.filter (op: op ? key && op.key.name != null) ops); };
in
{
	readsBack = tree:
		let
			readable = setting: setting.reads == null && setting.codec.kind != "snapshot"
				&& lib.all (key: key.name != null) (lib.attrValues setting.keys)
				&& (setting.codec ? decode || (lib.elem setting.codec.kind [ "bool" "enum" ] && !(appliedThroughCommand setting)));
			check = leaf: value:
				let
					option = lib.concatStringsSep "." leaf.path;
					encode = leaf.entry.codec.encode leaf.entry.keys;
					read = valueOf (simulate (encode value)) option leaf.entry;
				in
				lib.optional (read == null || encode read != encode value)
					"${option} = ${builtins.toJSON value} reads back as ${builtins.toJSON read}";
		in
		lib.concatMap (leaf: lib.concatMap (check leaf) leaf.entry.codec.examples)
			(lib.filter (leaf: readable leaf.entry) (module.settingsIn tree));

	# A script that prints the state `current` reads: every key the options store, each setting's
	# reader output, and snapshots captured into `snapshots`/<name>, or one into `capture.directory`.
	collect = { tree, scope ? null, only ? "", snapshots ? null, capture ? null }:
		let
			all = lib.filter (leaf: (scope == null || leaf.entry.scope == scope) && lib.hasPrefix only (lib.concatStringsSep "." leaf.path))
				(module.settingsIn tree);
			captureLeaf = lib.findFirst (leaf: option leaf == capture.option) (throw "no option ${capture.option}") all;
			leaves =
				if capture == null then all
				else if captureLeaf.entry.codec.kind != "snapshot" then throw "${capture.option} isn't a snapshot setting; set it in your configuration instead"
				else [ captureLeaf ];
			snapshotDirectory = leaf: if capture != null then capture.directory else "${snapshots}/${lib.last leaf.path}";
			option = leaf: lib.concatStringsSep "." leaf.path;
			keys = lib.filter (key: key.name != null) (lib.concatMap (leaf: lib.attrValues leaf.entry.keys) leaves);
			domains = lib.imap0 (at: group: { id = keyId (lib.head group); file = "domain-${toString at}.plist"; key = lib.head group; keys = lib.unique (map (key: key.name) group); })
				(lib.attrValues (lib.groupBy keyId keys));
			readers = lib.imap0 (at: leaf: { option = option leaf; file = "read-${toString at}.txt"; inherit (leaf.entry.reads) command; })
				(lib.filter (leaf: leaf.entry.reads != null) leaves);
			captured = lib.optionals (snapshots != null || capture != null) (lib.imap0 (at: leaf: {
				option = option leaf;
				directory = snapshotDirectory leaf;
				files = lib.imap0 (index: stored: {
					file = "snapshot-${toString at}-${toString index}.plist";
					source = stored.value;
					key = stored.value.name;
					out = "${stored.name}.plist";
				}) (lib.attrsToList leaf.entry.keys);
			}) (lib.filter (leaf: leaf.entry.codec.kind == "snapshot") leaves));
			manifest = {
				domains = map (domain: removeAttrs domain [ "key" ]) domains;
				reads = map (reader: removeAttrs reader [ "command" ]) readers;
				snapshots = map (snapshot: snapshot // { files = map (file: removeAttrs file [ "source" ]) snapshot.files; }) captured;
			};
			q = lib.escapeShellArg;
		in
		lib.concatStringsSep "\n" (
			[ "dir=$(/usr/bin/mktemp -d)" ]
			++ map (domain: "${render.export domain.key "\"$dir\"/${domain.file}"} 2>/dev/null") domains
			++ map (reader: "( ${reader.command} ) > \"$dir\"/${reader.file} 2>/dev/null &") readers
			++ lib.concatMap (snapshot: map (file: "${render.export file.source "\"$dir\"/${file.file}"} 2>/dev/null") snapshot.files) captured
			++ [
				"wait"
				"printf '%s' ${q (builtins.toJSON manifest)} > \"$dir\"/manifest.json"
				"/usr/bin/osascript -l JavaScript ${./preferences.js} \"$dir\""
				"/bin/rm -rf \"$dir\""
			]
		);

	current = { tree, collected ? {}, recorded ? null, build ? null, scope ? null, against ? null, againstFile ? null, only ? "", all ? false, uiRead ? false }:
		let
			# the defaults recorded on this macOS build, or on the latest one recorded before it
			builds = lib.sort (a: b: a < b) (map (lib.removeSuffix ".json") (lib.attrNames (lib.optionalAttrs (recorded != null) (builtins.readDir recorded))));
			defaultsBuild = if lib.elem build builds then build else lib.findFirst (recordedBuild: build != null && recordedBuild < build) null (lib.reverseList builds);
			recordedDefaults = lib.optionalAttrs (defaultsBuild != null) { defaults = lib.importJSON (recorded + "/${defaultsBuild}.json"); };
			state = { domains = {}; reads = {}; ui = {}; snapshots = {}; defaults = {}; } // recordedDefaults // collected;
			readScope = scopeName:
				let
					leaves = lib.filter (leaf: leaf.entry.scope == scopeName && lib.hasPrefix only (lib.concatStringsSep "." leaf.path)) (module.settingsIn tree);
					read = map (leaf:
						let
							option = lib.concatStringsSep "." leaf.path;
						in
						leaf // {
							inherit option;
							value =
								if leaf.entry.codec.kind == "snapshot" then (if state.snapshots ? ${option} then /. + state.snapshots.${option} else null)
								else valueOf state option leaf.entry;
						}) leaves;
					known = lib.filter (leaf: leaf.value != null) read;
					compared = if scope == null then against.${scopeName} or {} else against;
					atDefault = lib.filter (leaf: isDefault state leaf.option leaf.entry leaf.value) known;
					changed =
						if against != null then lib.filter (leaf: lib.attrByPath leaf.path null compared != leaf.value) known
						else if all then known
						else lib.filter (leaf: !(isDefault state leaf.option leaf.entry leaf.value)) known;
				in
				{
					values = lib.foldl' (tree: leaf: lib.recursiveUpdate tree (lib.setAttrByPath leaf.path leaf.value)) {} changed;
					read = lib.length known;
					changed = lib.length changed;
					atDefault = lib.length atDefault;
					defaultKnown = lib.count (leaf: (state.defaults ? ${leaf.option}) || codecDefault leaf.entry != null) known;
					unread = map (leaf: { inherit (leaf) option; ui = leaf.entry.verify != null; snapshot = leaf.entry.codec.kind == "snapshot"; })
						(lib.filter (leaf: leaf.value == null) read);
				};
			scopes = lib.genAttrs (if scope == null then [ "user" "system" ] else [ scope ]) readScope;
		in
		let
			total = field: lib.foldl' (sum: result: sum + result.${field}) 0 (lib.attrValues scopes);
			unread = lib.concatMap (result: result.unread) (lib.attrValues scopes);
			nothingStored = lib.filter (missing: !missing.snapshot) unread;
			fromUI = lib.filter (missing: missing.ui) nothingStored;
			snapshotsSkipped = lib.count (missing: missing.snapshot) unread;
			noDefault = total "read" - total "defaultKnown";
			count = n: one: many: "${toString n} ${if n == 1 then one else many}";
		in
		{
			text = lib.generators.toPretty {} (if scope == null then lib.mapAttrs (_: result: result.values) scopes else scopes.${scope}.values);
			summary = lib.concatStrings [
				"${toString (total "read")} settings read"
				(if againstFile != null then ", ${toString (total "changed")} differ from ${againstFile}"
				else lib.optionalString (!all) (", ${toString (total "atDefault")} at macOS's default left out"
					+ lib.optionalString (noDefault > 0) " (${count noDefault "has" "have"} no known default${lib.optionalString (defaultsBuild == null) "; none recorded for this macOS yet"})"))
				(lib.optionalString (nothingStored != []) ("; ${count (lib.length nothingStored) "has" "have"} nothing stored"
					+ lib.optionalString (fromUI != [] && !uiRead) " (--ui reads ${toString (lib.length fromUI)} of them from System Settings)"))
				(lib.optionalString (snapshotsSkipped > 0) "; ${toString snapshotsSkipped} snapshots skipped (--snapshots)")
			];
			nothingStored = lib.concatMapStringsSep "\n" (missing: "  ${missing.option}") nothingStored;
			fromUI = toString (map (missing: missing.option) fromUI);
		};
}
