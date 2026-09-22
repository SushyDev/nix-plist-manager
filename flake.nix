{
	description = "nix-plist-manager";
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
	};

	outputs = { self, nixpkgs, home-manager }:
		let
			supportedSystems = [ "x86_64-darwin" "aarch64-darwin" "x86_64-linux" ];
			forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
		in
		rec {
			darwinModules.default = import ./modules/darwin/default.nix;
			homeManagerModules.default = import ./modules/home-manager/default.nix;

			modules = {
				darwin = self.darwinModules.default;
				home-manager = self.homeManagerModules.default;
			};

			optionIndex =
				let
					lib = nixpkgs.lib;
					options = import ./lib/options.nix { inherit lib; };
				in
				import ./lib/optionIndex.nix { inherit lib; } options;

			documentation = forAllSystems (system:
				let
					pkgs = import nixpkgs { inherit system; };
					lib = nixpkgs.lib;
					options = import ./lib/options.nix { inherit lib; };
					generateMarkdown = import ./lib/generateMarkdown.nix { inherit lib; };

					data = lib.mapAttrs  (name: value:
						pkgs.writeTextFile {
							name = "";
							text = value;
							destination = name;
						}
					) (lib.listToAttrs (generateMarkdown options));
				in
				pkgs.symlinkJoin {
					name = "documentation";
					paths = lib.attrValues data;
				}
			);

			packages = forAllSystems (system:
				let
					pkgs = import nixpkgs { inherit system; };
					files = documentation.${system};
				in
				{
					website = pkgs.buildNpmPackage rec {
						pname = "nix-plist-manager-website";
						version = "1.0.0";
						src = ./docs;
						npmDepsHash = "sha256-w91qtncYEcZR80lzOpTo7QOsY3sUNzaP2vHM2O1n4Sg=";
						nativeBuildInputs = [ pkgs.cacert ];
						preBuild = ''
							cp -R ${files}/. src/content/docs/reference
						'';
						installPhase = ''
							runHook preInstall

							mkdir -p $out
							cp -r dist/* $out/

							runHook postInstall
						'';
					};
				}
			);

			apps = forAllSystems (system:
				let
					pkgs = import nixpkgs { inherit system; };
					inventory = pkgs.writeShellScript "inventory" ''
						export NIX_PLIST_MANAGER_ROOT="''${NIX_PLIST_MANAGER_ROOT:-$(${pkgs.git}/bin/git rev-parse --show-toplevel)}"
						exec ${pkgs.python3}/bin/python3 ${./tools/inventory/inventory.py} "$@"
					'';
				in
				{
					inventory = {
						type = "app";
						program = "${inventory}";
					};
				}
			);
		};
}

