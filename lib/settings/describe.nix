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
