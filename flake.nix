{
	description = "nix-plist-manager";
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";
	};

	outputs = { self, nixpkgs, flake-utils }:
		{
			darwinModules.default = import ./modules/default.nix;
		};
}
