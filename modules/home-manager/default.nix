{ lib, config, ... }:
let
	common = import ../common.nix { inherit lib; scope = "user"; };
	result = common.build config;
in
{
	imports = [ (import ../deprecations.nix { scope = "user"; }) ];

	inherit (common) options;

	config = lib.mkIf config.programs.nix-plist-manager.enable {
		inherit (result) assertions warnings;

		home.activation."nix-plist-manager" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
			${lib.optionalString (result.script != "") ''
				echo >&2 "User plist configuration... $USER"
				${result.script}
			''}
		'';
	};
}
