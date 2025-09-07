{ lib, config, ... }:
let
	options = import ../../lib/user-options.nix { inherit lib; };
in
{
	options = import ./options.nix { inherit lib config options; };
	config = lib.mkIf config.programs.nix-plist-manager.enable (import ./config.nix { inherit lib config options; });
}
