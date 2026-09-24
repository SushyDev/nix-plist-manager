{ lib, ops, storage, shortcuts }:
# A codec turns an option value into key writes. It supplies the option type (without the
# null and "unset" every setting accepts), the values documentation shows, and how verify
# specs name values.
#
# Codecs encode into `keys`: the setting's storage as an attrset, where a single key is
# called `value`.
let
	single = keys:
		if keys ? value && lib.length (lib.attrNames keys) == 1 then keys.value
		else throw "this value type needs a single storage key, not a record";

	isAbsent = value: lib.isAttrs value && value._type or null == "absent";

	writeOrDelete = key: value: if isAbsent value then ops.delete key else ops.write key value;

	# what one choice stores (see enum): a plain value, absent, or a record of storage name -> value
	writeStored = keys: stored:
		if lib.isAttrs stored && !(isAbsent stored) then
			lib.mapAttrsToList (name: value: writeOrDelete keys.${name} value) stored
		else [ (writeOrDelete (single keys) stored) ];

	# the value a codec stores in its single key, for codecs that nest it somewhere (inDict)
	storedValue = codec: value:
		if codec ? table then
			let stored = codec.table.${value}; in
			if lib.isAttrs stored && stored ? value then stored.value else stored
		else value;

	# for codecs made of named on/off switches: an option per switch, null leaving it as it is
	switchesType = names: lib.types.submodule {
		options = lib.mapAttrs (_: _: lib.mkOption {
			type = lib.types.nullOr lib.types.bool;
			default = null;
		}) names;
	};

	# the switches of a value that are set (not null)
	setSwitches = names: value: lib.filterAttrs (_: v: v != null) (lib.mapAttrs (name: _: value.${name} or null) names);

	bitSum = lib.foldl' builtins.bitOr 0;
in
rec {
	# the key is deleted, e.g. Multicolor is the absence of AppleAccentColor
	absent = { _type = "absent"; };

	bool = {
		kind = "bool";
		type = lib.types.bool;
		choices = [];
		examples = [ true false ];
		encode = keys: value: [ (ops.write (single keys) value) ];
		fromName = name: name == "true";
	};

	# for keys that mean the opposite of the control, e.g. AppleReduceDesktopTinting
	inverted = codec: codec // {
		encode = keys: value: codec.encode keys (!value);
	};

	# keep a codec's option type but store other values, e.g. a switch kept as 1 and 2:
	#   storedAs { true = 1; false = 2; } bool
	# or, for settings stored in several keys, { <storage name> = …; } per value, like enum
	storedAs = stored: codec: codec // {
		encode = keys: value: writeStored keys stored.${builtins.toJSON value};
	};

	# a codec's value kept as one entry of a dictionary, the rest of which is left alone:
	#   inDict "RTTWildcardContext" bool
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

	# an ordered list of strings, stored as an array, e.g. preferred languages
	strings = {
		kind = "list";
		read = { direct = true; };
		type = lib.types.listOf lib.types.str;
		choices = [];
		examples = [ [ "…" ] ];
		encode = keys: value: [ (ops.write (single keys) value) ];
		fromName = builtins.fromJSON;
	};

	# numbers stay strict: out of range fails evaluation
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

	# labels as System Settings shows them, each mapped to what is stored:
	#   a plain value            written to the single key
	#   absent                   the key is deleted
	#   { <storage name> = …; }  for settings stored in several keys; keys left out are untouched
	enum = table: {
		kind = "enum";
		inherit table;
		type = lib.types.enum (lib.attrNames table);
		choices = lib.attrNames table;
		examples = lib.attrNames table;
		encode = keys: label: writeStored keys table.${label};
		fromName = name: name;
	};

	# State that's arranged in System Settings rather than typed, like the menu bar layout: a
	# directory made by `nix run .#capture -- <option> <directory>`, with one plist per storage
	# entry. Each entry, a whole domain or one key, is replaced by what was captured.
	snapshot = {
		kind = "snapshot";
		read = { snapshot = true; };
		type = lib.types.path;
		choices = [];
		examples = [ "/path/to/snapshot" ];
		encode = keys: directory: lib.mapAttrsToList (name: key: ops.restore key "${directory}/${name}.plist") keys;
		fromName = name: name;
	};

	# named switches kept as entries of one dictionary, e.g. which features the Accessibility
	# Shortcut offers: { <switch> = <dictionary entry>; }
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

	# named switches kept as membership of an array of strings, e.g. the Spotlight categories
	# that are turned off: { <switch> = <array item>; }. `listedWhen` is the switch value that
	# puts an item in the array.
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

	# one switch kept as membership of an array of strings
	member = { item, listedWhen ? true }: bool // {
		encode = keys: value: [ (ops.setMembers (single keys) { ${item} = value == listedWhen; }) ];
	};

	# an integer bitmask set through named flags: { <switch> = <bit>; }. Flags left null keep
	# their current bit: the key is read and modified at activation instead of overwritten.
	flags = flagsWhenAbsent 0;

	# the same, for a key whose absence means some flags are set
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

	# one keyboard shortcut of com.apple.symbolichotkeys AppleSymbolicHotKeys, by its id: false
	# (off), true (on, with its default keys) or keys such as "⌘⇧S" (shortcuts.nix)
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
