{ lib, module }:
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

	current = { tree, state, scope ? null, against ? {}, only ? "" }:
		let
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
					changed = lib.filter (leaf: lib.attrByPath leaf.path null compared != leaf.value) known;
				in
				{
					values = lib.foldl' (tree: leaf: lib.recursiveUpdate tree (lib.setAttrByPath leaf.path leaf.value)) {} changed;
					read = lib.length known;
					changed = lib.length changed;
					unread = map (leaf: { inherit (leaf) option; ui = leaf.entry.verify != null; snapshot = leaf.entry.codec.kind == "snapshot"; })
						(lib.filter (leaf: leaf.value == null) read);
				};
			scopes = lib.genAttrs (if scope == null then [ "user" "system" ] else [ scope ]) readScope;
		in
		{
			text = lib.generators.toPretty {} (if scope == null then lib.mapAttrs (_: result: result.values) scopes else scopes.${scope}.values);
			read = lib.foldl' (sum: result: sum + result.read) 0 (lib.attrValues scopes);
			changed = lib.foldl' (sum: result: sum + result.changed) 0 (lib.attrValues scopes);
			unread = lib.concatMap (result: result.unread) (lib.attrValues scopes);
		};
}
