{
	description = "nix-plist-manager";
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
	};

	outputs = { self, nixpkgs, home-manager }:
		let
			supportedSystems = [ "x86_64-darwin" "aarch64-darwin" ];
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

			packages = forAllSystems (system:
				let
					pkgs = import nixpkgs { inherit system; };
					lib = nixpkgs.lib;
					options = import ./lib/options.nix { inherit lib; };
					generateMarkdown = import ./lib/generateMarkdown.nix { inherit lib; };
				in
				{
					websited = pkgs.stdenv.mkDerivation {
						name = "nix-plist-manager-website";
						src = ./.;
						buildInputs = [ pkgs.nodejs pkgs.cacert ];
						buildPhase = ''
							export HOME=$(mktemp -d)

							npm --yes create astro@latest -- --template starlight $HOME/project --yes --no-git --skip-houston
							cd $HOME/project

							mkdir -p $HOME/project/src/content/docs
							cat > $HOME/project/src/content/docs/index.md <<- 'EOF'
								---
								title: nix-plist-manager Documentation
								description: Documentation for nix-plist-manager
								---
								${lib.removeSuffix "\n\n" (generateMarkdown options)}
							EOF

							npm run build

							mkdir -p $out
							cp -r $HOME/project/dist/. $out
						'';
					};
				}
			);
		};
}

