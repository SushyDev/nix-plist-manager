{ lib, config, ... }:
let
	customLib = import ../lib { inherit lib; };
in
{
	options = import ./options.nix { inherit lib customLib config; };
	config = lib.mkIf config.nix-plist-manager.enable (import ./config.nix { inherit lib customLib config; });
}
