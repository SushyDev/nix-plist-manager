{ lib, config, ... }:
let
	options = import ../../lib/options.nix { inherit lib; };
in
{
	options = import ./options.nix { inherit lib config options; };
	config = (import ./config.nix { inherit lib config options; });
}
