{ lib, render, isSetting }:
let
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
		storage = lib.mapAttrsToList (as: key: storageKey key // { inherit as; }) setting.keys;
		commands = lib.listToAttrs (map (value: lib.nameValuePair (name value) (render.script (setting.plan value)))
			(setting.codec.examples ++ lib.optional (setting.option.type.check "unset") "unset"));
		verify = setting.verify;
		description = setting.option.description or "";
		example = lib.generators.toPretty { } (lib.head setting.codec.examples);
		canUnset = setting.option.type.check "unset";
		range = if setting.codec ? min then { inherit (setting.codec) min max; unit = setting.codec.unit or null; } else null;
		read = setting.codec.read or null;
		inherit (setting) reads;
		candidates =
			if lib.elem setting.codec.kind [ "bool" "enum" ] && !(appliedThroughCommand setting) then
				map (value: { inherit value; ops = map opJson (setting.codec.encode setting.keys value); }) setting.codec.examples
			else null;
		appliedThroughCommand = appliedThroughCommand setting;
	};
in
{
	isEntry = isSetting;

	describe = describeSetting;
}
