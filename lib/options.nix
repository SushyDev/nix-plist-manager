{ lib }:
let
	commandsLib = import ./commands.nix { inherit lib; };
	typesLib = import ./types.nix { inherit lib; };
	configLib = import ./config.nix { inherit lib; };
	pathLib = import ./paths.nix { inherit lib; };
	abstractionsLib = import ../lib/abstractions.nix { inherit lib commandsLib pathLib typesLib configLib; };
	settingsLib = import ./settings { inherit lib; };
in
{
	applications = {
		systemSettings = {
			general = import ./options/applications/systemSettings/general.nix { inherit lib settingsLib; };
			accessibility = import ./options/applications/systemSettings/accessibility.nix { inherit lib settingsLib; };
			appearance = import ./options/applications/systemSettings/appearance.nix { inherit lib settingsLib; };
			appleIntelligenceAndSiri = import ./options/applications/systemSettings/apple-intelligence-and-siri.nix { inherit lib settingsLib; };
			desktopAndDock = import ./options/applications/systemSettings/desktop-and-dock.nix { inherit lib commandsLib typesLib configLib pathLib abstractionsLib settingsLib; };
			displays = import ./options/applications/systemSettings/displays.nix { inherit lib settingsLib; };
			battery = import ./options/applications/systemSettings/battery.nix { inherit lib settingsLib; };
			menuBar = import ./options/applications/systemSettings/menu-bar.nix { inherit lib settingsLib; };
			spotlight = import ./options/applications/systemSettings/spotlight.nix { inherit lib settingsLib; };
			wallpaper = import ./options/applications/systemSettings/wallpaper.nix { inherit lib settingsLib; };
			notifications = import ./options/applications/systemSettings/notifications.nix { inherit lib settingsLib; };
			sound = import ./options/applications/systemSettings/sound.nix { inherit lib settingsLib; };
			focus = import ./options/applications/systemSettings/focus.nix { inherit lib commandsLib typesLib configLib pathLib abstractionsLib; };
		};
		finder = import ./options/applications/finder.nix { inherit lib commandsLib configLib pathLib typesLib; };
	};
}
