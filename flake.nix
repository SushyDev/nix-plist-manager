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

			# The script that applies one option value, as a configuration with only that value would:
			# type-checked, with the writes of settings it implies. Used by tools/verify.
			lib.commandFor = optionPath: value:
				let
					lib = nixpkgs.lib;
					result = self.lib.standalone (lib.setAttrByPath (lib.splitString "." optionPath) value);
					failed = result.user.assertions ++ result.system.assertions;
				in
				if failed != [] then throw (lib.concatStringsSep "\n" failed)
				else lib.concatStringsSep "\n" (lib.filter (script: script != "") [ result.user.script result.system.script ]);

			# `nix run .#apply` evaluates this: the scripts, warnings and failed assertions for a
			# set of option values, outside a system configuration
			lib.standalone = values:
				let
					lib = nixpkgs.lib;
					settingsLib = import ./lib/settings { inherit lib; };
					result = settingsLib.module.standalone {
						tree = import ./lib/options.nix { inherit lib; };
						inherit values;
					};
					scope = build: {
						inherit (build) script warnings;
						assertions = map (assertion: assertion.message) build.assertions;
					};
				in
				{
					user = scope result.user;
					system = scope result.system;
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

			checks = forAllSystems (system:
				let
					pkgs = import nixpkgs { inherit system; };
					failures = import ./lib/settings/tests.nix { inherit (nixpkgs) lib; };
					# every option's UI path starts at the app it's found in, so the docs say where the
					# setting is: "System Settings > Accessibility > Zoom > Advanced… > Smooth images"
					apps = [ "System Settings" "Finder" "Dock" "Menu bar" "App Store" ];
					unrooted = builtins.filter (entry: !(builtins.elem (builtins.head entry.path) apps)) self.optionIndex;
					# each option has its own path: the inventory links options to settings by it
					paths = map (entry: builtins.concatStringsSep " > " entry.path) self.optionIndex;
					duplicates = nixpkgs.lib.unique (builtins.filter (path: nixpkgs.lib.count (p: p == path) paths > 1) paths);
				in
				{
					ui-paths = pkgs.runCommand "ui-paths" {} (
						if duplicates != [] then throw "these UI paths belong to more than one option:\n${builtins.concatStringsSep "\n" duplicates}"
						else if unrooted == [] then "touch $out"
						else throw "these options' UI paths don't start at an app (${builtins.concatStringsSep ", " apps}):\n${builtins.concatStringsSep "\n" (map (entry: entry.option) unrooted)}"
					);

					settings = pkgs.runCommand "settings-tests" {} (
						if failures == [] then "touch $out"
						else throw "settings tests failed:\n${builtins.toJSON failures}"
					);
				}
			);

			apps = forAllSystems (system:
				let
					pkgs = import nixpkgs { inherit system; };
					inventory = pkgs.writeShellScript "inventory" ''
						export NIX_PLIST_MANAGER_ROOT="''${NIX_PLIST_MANAGER_ROOT:-$(${pkgs.git}/bin/git rev-parse --show-toplevel)}"
						exec ${pkgs.python3}/bin/python3 ${./tools/inventory/inventory.py} "$@"
					'';
					# needs Accessibility permission and the system swiftc, so macOS only
					verify = pkgs.writeShellScript "verify" ''
						export NIX_PLIST_MANAGER_ROOT="''${NIX_PLIST_MANAGER_ROOT:-$(${pkgs.git}/bin/git rev-parse --show-toplevel)}"
						exec ${pkgs.python3}/bin/python3 "$NIX_PLIST_MANAGER_ROOT/tools/verify/verify.py" "$@"
					'';
					# used from users' own configurations, so they read this flake's source, not the
					# repository they're run in
					apply = pkgs.writeShellScript "apply" (
						"export NIX_PLIST_MANAGER_ROOT=\"\${NIX_PLIST_MANAGER_ROOT:-${self}}\"\n"
						+ builtins.readFile ./tools/apply.sh
					);
					capture = pkgs.writeShellScript "capture" ''
						export NIX_PLIST_MANAGER_ROOT="''${NIX_PLIST_MANAGER_ROOT:-${self}}"
						exec ${pkgs.python3}/bin/python3 ${./tools/capture.py} "$@"
					'';
					current = pkgs.writeShellScript "current" ''
						export NIX_PLIST_MANAGER_ROOT="''${NIX_PLIST_MANAGER_ROOT:-${self}}"
						exec ${pkgs.python3}/bin/python3 ${./tools/current.py} "$@"
					'';
				in
				{
					apply = {
						type = "app";
						program = "${apply}";
					};
					capture = {
						type = "app";
						program = "${capture}";
					};
					current = {
						type = "app";
						program = "${current}";
					};
					inventory = {
						type = "app";
						program = "${inventory}";
					};
					verify = {
						type = "app";
						program = "${verify}";
					};
				}
			);
		};
}

