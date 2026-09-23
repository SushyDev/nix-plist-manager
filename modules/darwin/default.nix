{ lib, config, ... }:
let
	common = import ../common.nix { inherit lib; scope = "system"; };
	result = common.build config;
in
{
	imports = [ (import ../deprecations.nix { scope = "system"; }) ];

	inherit (common) options;

	config = lib.mkIf config.programs.nix-plist-manager.enable {
		inherit (result) assertions warnings;

		system.activationScripts.defaults.text = lib.mkAfter ''
			${lib.optionalString (result.script != "") ''
				echo >&2 "System plist configuration..."
				${result.script}
			''}
		'';
	};
}
