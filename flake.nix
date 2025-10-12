{
	description = "nix-plist-manager";
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
	};

	outputs = { self, nixpkgs, home-manager }:
		let
			supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];
			forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
		in
		{
			darwinModules.default = import ./modules/darwin/default.nix;
			homeManagerModules.default = import ./modules/home-manager/default.nix;

			modules = {
				darwin = self.darwinModules.default;
				home-manager = self.homeManagerModules.default;
			};

			documentation = forAllSystems (system:
				let
					pkgs = import nixpkgs { inherit system; };
					lib = nixpkgs.lib;
					options = import ./lib/options.nix { inherit lib; };
					generateMarkdown = import ./lib/generateMarkdown.nix { inherit lib; };
				in
				pkgs.runCommand "home-manager-docs" {} ''
					mkdir -p $out
					cat > $out/documentation.md <<- 'EOF'
						${lib.removeSuffix "\n\n" (generateMarkdown options)}
					EOF
				''
			);
		};
}

