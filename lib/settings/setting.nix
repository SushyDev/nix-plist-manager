{ lib, ops, behaviorsLib }:
{
	setting = {
		ui,
		storage,
		value,
		behaviors ? [],
		relations ? [],
		verify ? null,
		reads ? null,
		description ? "",
		canUnset ? true,
	}:
		let
			keys = if storage._type or null == "storageKey" then { value = storage; } else storage;
			scopes = lib.unique (map (key: key.scope) (lib.attrValues keys));
			scope =
				if lib.length scopes == 1 then lib.head scopes
				else throw "setting ${lib.concatStringsSep " > " ui} mixes user and system storage";

			encode = v:
				if canUnset && v == "unset" then map ops.delete (lib.attrValues keys)
				else value.encode keys v;
		in
		{
			_type = "setting";
			inherit ui keys scope relations description reads canUnset;
			codec = value;

			option = lib.mkOption {
				inherit description;
				default = null;
				type = lib.types.nullOr (if canUnset then lib.types.either value.type (lib.types.enum [ "unset" ]) else value.type);
			};

			plan = v:
				if v == null then []
				else lib.foldl' (plan: behavior: behavior { inherit keys; value = v; } plan)
					(encode v)
					(behaviors ++ behaviorsLib.defaults);

			verify = lib.mapNullable (spec: spec // {
				open = spec.open or [];
				operate = spec.operate or null;
				sideEffects = spec.sideEffects or null;
				expect = lib.mapAttrsToList (name: controls: {
					value = value.fromName name;
					inherit controls;
				}) spec.expect;
			}) verify;
		};

	family = members: settings: lib.mapAttrs (name: args: settings (args // { inherit name; })) members;

	isSetting = value: lib.isAttrs value && value._type or null == "setting";
}
