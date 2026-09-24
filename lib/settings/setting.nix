{ lib, ops, behaviorsLib }:
{
	# Register a setting. Everything else, the option, the commands, the docs, the
	# storage and the verify spec, is derived from this.
	#
	#   ui          the full path to the control, in the UI's own words, starting at the app:
	#               [ "System Settings" "Accessibility" "Zoom" "Advanced…" "Smooth images" ].
	#               A sheet is the button that opens it: "Advanced…", or "Speak selection (i)" for
	#               an info button. The docs show it as the way to the setting.
	#   storage     one key (storage.nix) or an attrset of named keys
	#   value       a codec (codecs.nix)
	#   behaviors   extra plan rewrites (behaviors.nix); `appliesThrough` goes first
	#   relations   rules against other settings (relations.nix)
	#   verify      what System Settings shows per value, for `nix run .#verify -- check`:
	#               { pane; open ? []; operate ? null; expect = { <value> = { <control> = <expected>; }; }; }
	#               see tools/verify/verify.py for the control syntax
	setting = {
		ui,
		storage,
		value,
		behaviors ? [],
		relations ? [],
		verify ? null,
		description ? "",
		# false when there is no safe way back to the default, e.g. settings applied through a
		# command like pmset: the option then doesn't accept "unset"
		canUnset ? true,
	}:
		let
			keys = if storage._type or null == "storageKey" then { value = storage; } else storage;
			scopes = lib.unique (map (key: key.scope) (lib.attrValues keys));
			scope =
				if lib.length scopes == 1 then lib.head scopes
				else throw "setting ${lib.concatStringsSep " > " ui} mixes user and system storage";

			encode = v:
				if v == "unset" then map ops.delete (lib.attrValues keys)
				else value.encode keys v;
		in
		{
			_type = "setting";
			inherit ui keys scope relations description;
			codec = value;

			option = lib.mkOption {
				inherit description;
				default = null;
				type = lib.types.nullOr (if canUnset then lib.types.either value.type (lib.types.enum [ "unset" ]) else value.type);
			};

			# the operations that apply `v`; null means not managed
			plan = v:
				if v == null then []
				else lib.foldl' (plan: behavior: behavior { inherit keys; value = v; } plan)
					(encode v)
					(behaviors ++ behaviorsLib.defaults);

			verify = lib.mapNullable (spec: spec // {
				open = spec.open or [];
				operate = spec.operate or null;
				expect = lib.mapAttrsToList (name: controls: {
					value = value.fromName name;
					inherit controls;
				}) spec.expect;
			}) verify;
		};

	# a table of settings with the same shape, e.g. the four hot corners:
	#   family { topLeft = { corner = "tl"; }; … } ({ name, corner }: { action = setting { … }; })
	family = members: settings: lib.mapAttrs (name: args: settings (args // { inherit name; })) members;

	isSetting = value: lib.isAttrs value && value._type or null == "setting";
}
