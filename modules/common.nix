{ lib, scope }:
let
	settingsLib = import ../lib/settings { inherit lib; };
	tree = import ../lib/options.nix { inherit lib; };
in
{
	inherit settingsLib tree;

	options.programs.nix-plist-manager = {
		enable = lib.mkEnableOption "nix-plist-manager";

		options = settingsLib.module.optionTree { inherit tree scope; };

		ignoreWarnings = lib.mkOption {
			type = lib.types.listOf lib.types.str;
			default = [];
			example = [ "applications.systemSettings.appearance.textHighlightColor" ];
			description = ''
				Settings (by option path) or single relations ("<setting> -> <other setting>") whose
				warnings you don't want to see, e.g. because you leave the other setting unmanaged on
				purpose. Each warning ends with the entry that silences it.
			'';
		};
	};

	build = config: settingsLib.module.build {
		inherit tree scope;
		values = config.programs.nix-plist-manager.options;
		inherit (config.programs.nix-plist-manager) ignoreWarnings;
	};
}
