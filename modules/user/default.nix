{ lib, config, ... }:
let
	options = import ../../lib/user-options.nix { inherit lib config; };
in
{
	options = import ./options.nix { inherit lib config options; };
	config = lib.mkIf config.nix-plist-manager.enable (import ./config.nix { inherit lib config systemOptions userOptions; });
}
