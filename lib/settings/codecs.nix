{ lib, ops, storage, shortcuts }:
let
	single = keys:
		if keys ? value && lib.length (lib.attrNames keys) == 1 then keys.value
		else throw "this value type needs a single storage key, not a record";

	isAbsent = value: lib.isAttrs value && value._type or null == "absent";

	writeOrDelete = key: value: if isAbsent value then ops.delete key else ops.write key value;

	writeStored = keys: stored:
		if lib.isAttrs stored && !(isAbsent stored) then
			lib.mapAttrsToList (name: value: writeOrDelete keys.${name} value) stored
		else [ (writeOrDelete (single keys) stored) ];

	storedValue = codec: value:
		if codec ? table then
			let stored = codec.table.${value}; in
			if lib.isAttrs stored && stored ? value then stored.value else stored
		else value;

	switchesType = names: lib.types.submodule {
		options = lib.mapAttrs (_: _: lib.mkOption {
			type = lib.types.nullOr lib.types.bool;
			default = null;
		}) names;
	};

	setSwitches = names: value: lib.filterAttrs (_: v: v != null) (lib.mapAttrs (name: _: value.${name} or null) names);

	bitSum = lib.foldl' builtins.bitOr 0;
in
rec {
	absent = { _type = "absent"; };

	bool = {
		kind = "bool";
		type = lib.types.bool;
		choices = [];
		examples = [ true false ];
		encode = keys: value: [ (ops.write (single keys) value) ];
		fromName = name: name == "true";
	};

	inverted = codec: codec // {
		encode = keys: value: codec.encode keys (!value);
	};

	storedAs = stored: codec: codec // {
		encode = keys: value: writeStored keys stored.${builtins.toJSON value};
	};

	inDict = entry: codec: codec // {
		encode = keys: value: [ (ops.mergeDict (single keys) { ${entry} = storedValue codec value; }) ];
	};

	text = {
		kind = "string";
		read = { direct = true; };
		type = lib.types.str;
		choices = [];
		examples = [ "…" ];
		encode = keys: value: [ (ops.write (single keys) value) ];
		fromName = name: name;
	};

	strings = {
		kind = "list";
		read = { direct = true; };
		type = lib.types.listOf lib.types.str;
		choices = [];
		examples = [ [ "…" ] ];
		encode = keys: value: [ (ops.write (single keys) value) ];
		fromName = builtins.fromJSON;
	};

	number = { min, max, stored ? null, unit ? null }:
		let
			float = stored == "float" || lib.isFloat min || lib.isFloat max;
		in
		{
			kind = "number";
			read = { direct = true; };
			inherit min max unit;
			type = if float then lib.types.numbers.between min max else lib.types.ints.between min max;
			choices = [];
			examples = [ min max ];
			encode = keys: value:
				let
					key = single keys;
				in
				[ (ops.write (if stored != null then key // { type = stored; } else key) value) ];
			fromName = builtins.fromJSON;
		};

	enum = table: {
		kind = "enum";
		inherit table;
		type = lib.types.enum (lib.attrNames table);
		choices = lib.attrNames table;
		examples = lib.attrNames table;
		encode = keys: label: writeStored keys table.${label};
		fromName = name: name;
	};

	snapshot = {
		kind = "snapshot";
		read = { snapshot = true; };
		type = lib.types.path;
		choices = [];
		examples = [ "/path/to/snapshot" ];
		encode = keys: directory: lib.mapAttrsToList (name: key: ops.restore key "${directory}/${name}.plist") keys;
		fromName = name: name;
	};

	dictSwitches = entries: {
		kind = "switches";
		read = { dict = entries; };
		type = switchesType entries;
		choices = lib.attrNames entries;
		examples = [ (lib.mapAttrs (_: _: true) entries) ];
		encode = keys: value:
			let
				set = setSwitches entries value;
			in
			lib.optional (set != {})
				(ops.mergeDict (single keys) (lib.mapAttrs' (name: on: lib.nameValuePair entries.${name} on) set));
		fromName = builtins.fromJSON;
	};

	members = { items, listedWhen ? true }: {
		kind = "switches";
		read = { members = items; inherit listedWhen; };
		type = switchesType items;
		choices = lib.attrNames items;
		examples = [ (lib.mapAttrs (_: _: true) items) ];
		encode = keys: value:
			let
				set = setSwitches items value;
			in
			lib.optional (set != {})
				(ops.setMembers (single keys) (lib.mapAttrs' (name: on: lib.nameValuePair items.${name} (on == listedWhen)) set));
		fromName = builtins.fromJSON;
	};

	member = { item, listedWhen ? true }: bool // {
		encode = keys: value: [ (ops.setMembers (single keys) { ${item} = value == listedWhen; }) ];
	};

	# Flags left null keep their current bit, since the key is modified at activation rather than overwritten.
	flags = flagsWhenAbsent 0;

	flagsWhenAbsent = absentValue: bits: {
		kind = "flags";
		read = { flags = bits; absent = absentValue; };
		type = switchesType bits;
		choices = lib.attrNames bits;
		examples = [ (lib.mapAttrs (_: _: true) bits) ];
		encode = keys: value:
			let
				managed = lib.intersectAttrs (setSwitches bits value) bits;
				mask = bitSum (lib.attrValues managed);
				set = bitSum (lib.attrValues (lib.filterAttrs (name: _: value.${name}) managed));
			in
			lib.optional (mask != 0) (ops.writeFlags (single keys) mask set // { absent = absentValue; });
		fromName = builtins.fromJSON;
	};

	hotKey = id: {
		kind = "shortcut";
		read = { hotKey = id; inherit (shortcuts) names; };
		type = lib.types.either lib.types.bool shortcuts.type;
		choices = [];
		examples = [ false "⌘⇧S" ];
		encode = keys: choice: [
			(ops.mergeDict (single keys) {
				${toString id} =
					if lib.isBool choice then { enabled = choice; }
					else { enabled = true; value = { type = "standard"; parameters = shortcuts.hotKeyParameters choice; }; };
			})
		];
		fromName = name: if name == "true" || name == "false" then builtins.fromJSON name else name;
	};
}
