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

			# The scripts for a set of option values, outside a system configuration, checked as one
			# would be: failed assertions stop evaluation and warnings are printed.
			lib.standalone = values:
				let
					lib = nixpkgs.lib;
					settingsLib = import ./lib/settings { inherit lib; };
					result = settingsLib.module.standalone {
						tree = import ./lib/options.nix { inherit lib; };
						inherit values;
					};
					failed = map (assertion: assertion.message) (result.user.assertions ++ result.system.assertions);
				in
				if failed != [] then throw (lib.concatStringsSep "\n" failed)
				else lib.foldr lib.warn { user = result.user.script; system = result.system.script; }
					(result.user.warnings ++ result.system.warnings);

			# The script that applies one option value, with the writes of settings it implies. Used
			# by tools/verify.py, which runs it as root when the option is nix-darwin's.
			lib.commandFor = optionPath: value:
				let
					lib = nixpkgs.lib;
					scripts = self.lib.standalone (lib.setAttrByPath (lib.splitString "." optionPath) value);
				in
				lib.concatStringsSep "\n" (lib.filter (script: script != "") [ scripts.user scripts.system ]);

			# What `nix run .#apply` runs: user settings as you, system settings through sudo.
			lib.applyScript = values:
				let
					lib = nixpkgs.lib;
					scripts = self.lib.standalone values;
				in
				lib.concatStringsSep "\n" (lib.filter (script: script != "") [
					scripts.user
					(lib.optionalString (scripts.system != "") "sudo /bin/bash -c ${lib.escapeShellArg scripts.system}")
				]);

			optionIndex =
				let
					lib = nixpkgs.lib;
					options = import ./lib/options.nix { inherit lib; };
				in
				import ./lib/optionIndex.nix { inherit lib; } options;

			# what the website is generated from: every option (optionIndex) and coverage.json, which
			# says what's verified and what isn't covered. docs/scripts/generate.mjs turns it into pages.
			documentation = forAllSystems (system:
				let
					pkgs = import nixpkgs { inherit system; };
				in
				pkgs.runCommand "documentation" { } ''
					mkdir -p $out
					cp ${pkgs.writeText "options.json" (builtins.toJSON self.optionIndex)} $out/options.json
					cp ${./coverage.json} $out/coverage.json
				''
			);

			packages = forAllSystems (system:
				let
					pkgs = import nixpkgs { inherit system; };
				in
				{
					website = pkgs.buildNpmPackage {
						pname = "nix-plist-manager-website";
						version = "1.0.0";
						src = ./docs;
						npmDepsHash = "sha256-w91qtncYEcZR80lzOpTo7QOsY3sUNzaP2vHM2O1n4Sg=";
						nativeBuildInputs = [ pkgs.cacert ];
						DOCS_DATA = documentation.${system};
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
					apps = [ "System Settings" "Finder" "Dock" "Menu bar" "App Store" "Voice Memos" "News" "Journal" ];
					unrooted = builtins.filter (entry: !(builtins.elem (builtins.head entry.path) apps)) self.optionIndex;
					# each option has its own path, so the docs can tell them apart
					paths = map (entry: builtins.concatStringsSep " > " entry.path) self.optionIndex;
					duplicates = nixpkgs.lib.unique (builtins.filter (path: nixpkgs.lib.count (p: p == path) paths > 1) paths);
					# coverage.json only lists options that exist
					known = map (entry: entry.option) self.optionIndex;
					verified = builtins.concatLists (builtins.attrValues (builtins.fromJSON (builtins.readFile ./coverage.json)).verified);
					stale = builtins.filter (option: !(builtins.elem option known)) verified;
				in
				{
					ui-paths = pkgs.runCommand "ui-paths" {} (
						if duplicates != [] then throw "these UI paths belong to more than one option:\n${builtins.concatStringsSep "\n" duplicates}"
						else if unrooted == [] then "touch $out"
						else throw "these options' UI paths don't start at an app (${builtins.concatStringsSep ", " apps}):\n${builtins.concatStringsSep "\n" (map (entry: entry.option) unrooted)}"
					);

					coverage = pkgs.runCommand "coverage" {} (
						if stale == [] then "touch $out"
						else throw "coverage.json lists options that don't exist:\n${builtins.concatStringsSep "\n" stale}"
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
					# needs Accessibility permission and the system swiftc, so macOS only
					verify = pkgs.writeShellScript "verify" ''
						export NIX_PLIST_MANAGER_ROOT="''${NIX_PLIST_MANAGER_ROOT:-$(${pkgs.git}/bin/git rev-parse --show-toplevel)}"
						exec ${pkgs.python3}/bin/python3 "$NIX_PLIST_MANAGER_ROOT/tools/verify.py" "$@"
					'';
					# compiled with the system's swiftc on first use, once per version of the source
					watch = pkgs.writeShellScript "watch" ''
						cache="''${XDG_CACHE_HOME:-$HOME/.cache}/nix-plist-manager"
						binary="$cache/$(basename ${./tools/watch.swift} .swift)"
						if [ ! -x "$binary" ]; then
							mkdir -p "$cache"
							/usr/bin/swiftc -O ${./tools/watch.swift} -o "$binary"
						fi
						exec "$binary" "$@"
					'';
					# used from users' own configurations, so they read this flake's source, not the
					# repository they're run in
					apply = pkgs.writeShellScript "apply" (
						"export NIX_PLIST_MANAGER_ROOT=\"\${NIX_PLIST_MANAGER_ROOT:-${self}}\"\n"
						+ builtins.readFile ./tools/apply.sh
					);
					capture = pkgs.writeShellScript "capture" ''
						export NIX_PLIST_MANAGER_ROOT="''${NIX_PLIST_MANAGER_ROOT:-${self}}"
						exec ${pkgs.python3}/bin/python3 ${self}/tools/current.py capture "$@"
					'';
					current = pkgs.writeShellScript "current" ''
						export NIX_PLIST_MANAGER_ROOT="''${NIX_PLIST_MANAGER_ROOT:-${self}}"
						exec ${pkgs.python3}/bin/python3 ${self}/tools/current.py "$@"
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
					verify = {
						type = "app";
						program = "${verify}";
					};
					watch = {
						type = "app";
						program = "${watch}";
					};
				}
			);
		};
}

