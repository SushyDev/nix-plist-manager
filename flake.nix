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
		{
			darwinModules.default = import ./modules/darwin/default.nix;
			homeManagerModules.default = import ./modules/home-manager/default.nix;

			modules = {
				darwin = self.darwinModules.default;
				home-manager = self.homeManagerModules.default;
			};

			# documentation = forAllSystems (system:
			# 	let
			# 		pkgs = import nixpkgs { inherit system; };
			# 		lib = nixpkgs.lib;
			# 		options = import ./lib/options.nix { inherit lib; };
			# 		generateMarkdown = import ./lib/generateMarkdown.nix { inherit lib; };
			# 	in
			# 	pkgs.runCommand "home-manager-docs" {} ''
			# 		mkdir -p $out
			# 		cat > $out/documentation.md <<- 'EOF'
			# 			${lib.removeSuffix "\n\n" (generateMarkdown options)}
			# 		EOF
			# 	''
			# );

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

					files = pkgs.symlinkJoin {
						name = "documentation";
						paths = lib.attrValues data;
					};
				in
				{
					website = pkgs.buildNpmPackage rec {
						pname = "nix-plist-manager-website";
						version = "1.0.0";
						src = ./docs;
						npmDepsHash = "sha256-w91qtncYEcZR80lzOpTo7QOsY3sUNzaP2vHM2O1n4Sg=";
						nativeBuildInputs = [ pkgs.coreutils pkgs.cacert ];
						preBuild = ''
							mkdir -p src/content/docs/result
							cp -R ${files}/. src/content/docs/result
						'';
						preInstall = ''
							find ./dist -type f -exec sed -i 's#/_astro#/nix-plist-manager/_astro#g' {} +
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
		};
}

