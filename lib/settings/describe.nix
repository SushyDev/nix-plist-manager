{ lib, render, isSetting }:
# One description of an option, for the docs, optionIndex and the verify tools, whether it's
# a setting or an option that doesn't use `setting` yet.
let
	isLegacy = value: lib.isAttrs value && value ? path && value ? mapping && value ? config;

	name = value:
		if lib.isAttrs value then "{ ${lib.concatStringsSep "; " (lib.mapAttrsToList (k: v: "${k} = ${builtins.toJSON v}") value)}; }"
		else if lib.isString value then value
		else builtins.toJSON value;

	storageKey = key: {
		inherit (key) domain byHost scope;
		key = key.name;
	} // lib.optionalAttrs (key.type != null) { inherit (key) type; };

	opJson = op: removeAttrs op [ "key" ] // lib.optionalAttrs (op ? key) { key = storageKey op.key; };

	appliedThroughCommand = setting: lib.any (op: op.op == "run") (setting.plan (lib.head setting.codec.examples));

	describeSetting = setting: {
		path = setting.ui;
		module = if setting.scope == "system" then "darwin" else "home-manager";
		type = setting.option.type.description;
		kind = setting.codec.kind;
		choices = setting.codec.choices;
		# `as` is the entry's name in the setting's storage, which `capture` names its files by
		storage = lib.mapAttrsToList (as: key: storageKey key // { inherit as; }) setting.keys;
		# the script each example value renders to
		commands = lib.listToAttrs (map (value: lib.nameValuePair (name value) (render.script (setting.plan value)))
			(setting.codec.examples ++ lib.optional (setting.option.type.check "unset") "unset"));
		verify = setting.verify;
		# how `nix run .#current` reads the value back: the codec's own reader, or, for values
		# picked from a list, what each one writes
		read = setting.codec.read or null;
		candidates =
			if lib.elem setting.codec.kind [ "bool" "enum" ] && !(appliedThroughCommand setting) then
				map (value: { inherit value; ops = map opJson (setting.codec.encode setting.keys value); }) setting.codec.examples
			else null;
		# applied through a command, so the keys may not say what is in effect
		appliedThroughCommand = appliedThroughCommand setting;
	};

	describeLegacy = option: {
		inherit (option) path;
		module = if option.config.perUser then "home-manager" else "darwin";
		type = option.option.type.description;
		kind = "legacy";
		choices = [];
		commands = lib.mapAttrs (_: entry:
			if lib.isFunction entry.command then entry.command "value" else toString entry.command
		) option.mapping;
		verify = null;
	};
in
{
	isEntry = value: isSetting value || isLegacy value;

	describe = value: if isSetting value then describeSetting value else describeLegacy value;
}
