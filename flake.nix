{
	description = "nix-plist-manager";
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
	};

	outputs = { self, nixpkgs }:
		{
			darwinModules.default = import ./modules/system/default.nix;
			homeMangerModules.default = import ./modules/user/default.nix;

			modules = {
				darwin = self.darwinModules.default;
				home-manager = self.homeMangerModules.default;
			};
		};
}

