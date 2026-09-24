{
	description = "Evaluates the nix-plist-manager modules inside real home-manager and nix-darwin configurations";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		nix-darwin = {
			url = "github:nix-darwin/nix-darwin";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		nix-plist-manager.url = "path:../..";
	};

	outputs = { nixpkgs, home-manager, nix-darwin, nix-plist-manager, ... }:
		let
			system = "aarch64-darwin";
			pkgs = nixpkgs.legacyPackages.${system};

			# user settings are home-manager's, system settings nix-darwin's
			userSettings = {
				applications.systemSettings.appearance = {
					accentColor = "Graphite";
					textHighlightColor = "Blue";
				};
				applications.systemSettings.desktopAndDock.dock.size = 48;
			};
			systemSettings = {
				applications.systemSettings.general.softwareUpdate.automaticallyDownloadNewUpdatesWhenAvailable = true;
			};

			home = home-manager.lib.homeManagerConfiguration {
				inherit pkgs;
				modules = [
					nix-plist-manager.homeManagerModules.default
					{
						home = { username = "test"; homeDirectory = "/Users/test"; stateVersion = "25.05"; };
						programs.nix-plist-manager = { enable = true; options = userSettings; };
					}
				];
			};

			darwin = nix-darwin.lib.darwinSystem {
				inherit system;
				modules = [
					nix-plist-manager.darwinModules.default
					{
						system.stateVersion = 6;
						system.primaryUser = "test";
						programs.nix-plist-manager = { enable = true; options = systemSettings; };
					}
				];
			};
		in
		{
			# nix eval --raw ./tests/modules#home   /   #darwin
			home = home.config.home.activation."nix-plist-manager".data;
			homeWarnings = home.config.warnings;
			darwin = darwin.config.system.activationScripts.defaults.text;

			checks.${system} = {
				home = home.activationPackage;
				darwin = darwin.system;
			};
		};
}
