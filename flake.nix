{
	description = "nix-plist-manager";
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
	};

	outputs = { self, nixpkgs }:
		let
			supportedSystems = [ "x86_64-darwin" "aarch64-darwin" "x86_64-linux" ];
			lib = nixpkgs.lib;
			forAllSystems = f: lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
			settingsLib = import ./lib/settings { inherit lib; };
			tree = import ./lib/options.nix { inherit lib; };
			nonEmpty = lib.filter (script: script != "");
		in
		{
			darwinModules.default = import ./modules/darwin/default.nix;
			homeManagerModules.default = import ./modules/home-manager/default.nix;

			modules = {
				darwin = self.darwinModules.default;
				home-manager = self.homeManagerModules.default;
			};

			lib.standalone = values:
				let
					result = settingsLib.module.standalone { inherit tree values; };
					failed = map (assertion: assertion.message) (result.user.assertions ++ result.system.assertions);
				in
				if failed != [] then throw (lib.concatStringsSep "\n" failed)
				else lib.foldr lib.warn { user = result.user.script; system = result.system.script; }
					(result.user.warnings ++ result.system.warnings);

			lib.commandFor = optionPath: value:
				let
					scripts = self.lib.standalone (lib.setAttrByPath (lib.splitString "." optionPath) value);
				in
				lib.concatStringsSep "\n" (nonEmpty [ scripts.user scripts.system ]);

			lib.applyScript = values:
				let
					scripts = self.lib.standalone values;
				in
				lib.concatStringsSep "\n" (nonEmpty [
					scripts.user
					(lib.optionalString (scripts.system != "") "sudo /bin/bash -c ${lib.escapeShellArg scripts.system}")
				]);

			optionIndex = import ./lib/optionIndex.nix { inherit lib; } tree;

			documentation = forAllSystems (pkgs: pkgs.runCommand "documentation" { } ''
				mkdir -p $out
				cp ${pkgs.writeText "options.json" (builtins.toJSON self.optionIndex)} $out/options.json
				cp ${./coverage.json} $out/coverage.json
			'');

			packages = forAllSystems (pkgs: {
				website = pkgs.buildNpmPackage {
					pname = "nix-plist-manager-website";
					version = "1.0.0";
					src = ./docs;
					npmDepsHash = "sha256-w91qtncYEcZR80lzOpTo7QOsY3sUNzaP2vHM2O1n4Sg=";
					nativeBuildInputs = [ pkgs.cacert ];
					DOCS_DATA = self.documentation.${pkgs.stdenv.hostPlatform.system};
					installPhase = ''
						runHook preInstall
						mkdir -p $out
						cp -r dist/* $out/
						runHook postInstall
					'';
				};
			});

			checks = forAllSystems (pkgs:
				let
					check = name: message: failures: pkgs.runCommand name { } (
						if failures == [] then "touch $out"
						else throw "${message}:\n${lib.concatStringsSep "\n" failures}"
					);
					apps = [ "System Settings" "Finder" "Dock" "Menu bar" "App Store" "Voice Memos" "News" "Journal" ];
					paths = map (entry: lib.concatStringsSep " > " entry.path) self.optionIndex;
					known = map (entry: entry.option) self.optionIndex;
					verified = lib.concatLists (lib.attrValues (lib.importJSON ./coverage.json).verified);
				in
				{
					ui-paths = check "ui-paths" "UI paths that belong to more than one option, or don't start at an app"
						(lib.unique (lib.filter (path: lib.count (p: p == path) paths > 1) paths)
						++ map (entry: entry.option) (lib.filter (entry: !(lib.elem (lib.head entry.path) apps)) self.optionIndex));

					coverage = check "coverage" "coverage.json lists options that don't exist" (lib.filter (option: !(lib.elem option known)) verified);

					settings = check "settings-tests" "settings tests failed" (map builtins.toJSON (import ./lib/settings/tests.nix { inherit lib; }));
				}
			);

			apps = forAllSystems (pkgs:
				let
					app = name: script: { type = "app"; program = "${pkgs.writeShellScript name script}"; };
					# Users run these from their own configurations, so they use this flake's source.
					fromFlake = "export NIX_PLIST_MANAGER_ROOT=\"\${NIX_PLIST_MANAGER_ROOT:-${self}}\"\n";
					python = "${pkgs.python3}/bin/python3";
				in
				{
					apply = app "apply" (fromFlake + builtins.readFile ./tools/apply.sh);
					current = app "current" (fromFlake + "exec ${python} ${self}/tools/current.py \"$@\"");
					capture = app "capture" (fromFlake + "exec ${python} ${self}/tools/current.py capture \"$@\"");
					verify = app "verify" ''
						export NIX_PLIST_MANAGER_ROOT="''${NIX_PLIST_MANAGER_ROOT:-$(${pkgs.git}/bin/git rev-parse --show-toplevel)}"
						exec ${python} "$NIX_PLIST_MANAGER_ROOT/tools/verify.py" "$@"
					'';
					watch = app "watch" ''
						binary="''${XDG_CACHE_HOME:-$HOME/.cache}/nix-plist-manager/$(basename ${./tools/watch.swift} .swift)"
						if [ ! -x "$binary" ]; then
							mkdir -p "$(dirname "$binary")"
							/usr/bin/swiftc -O ${./tools/watch.swift} -o "$binary"
						fi
						exec "$binary" "$@"
					'';
				}
			);
		};
}
