{ lib, render }:
let
	name = value:
		if lib.isAttrs value then "{ ${lib.concatStringsSep "; " (lib.mapAttrsToList (k: v: "${k} = ${builtins.toJSON v}") value)}; }"
		else if lib.isString value then value
		else builtins.toJSON value;

	storageKey = key: {
		inherit (key) domain byHost scope;
		key = key.name;
	} // lib.optionalAttrs (key.type != null) { inherit (key) type; };

	describeSetting = setting: {
		path = setting.ui;
		module = if setting.scope == "system" then "darwin" else "home-manager";
		type = setting.option.type.description;
		kind = setting.codec.kind;
		choices = setting.codec.choices;
		storage = lib.mapAttrsToList (as: key: storageKey key // { inherit as; }) setting.keys;
		commands = lib.listToAttrs (map (value: lib.nameValuePair (name value) (render.script (setting.plan value)))
			(setting.codec.examples ++ lib.optional setting.canUnset "unset"));
		verify = setting.verify;
		description = setting.option.description or "";
		example = lib.generators.toPretty { } (lib.head setting.codec.examples);
		inherit (setting) canUnset;
		reads = lib.mapNullable (reads: { inherit (reads) command; }) setting.reads;
		range = if setting.codec ? min then { inherit (setting.codec) min max; unit = setting.codec.unit or null; } else null;
	};
in
{
	describe = describeSetting;
}
