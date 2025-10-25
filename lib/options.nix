{ lib }:
let
	commandsLib = import ./commands.nix { inherit lib; };
	typesLib = import ./types.nix { inherit lib; };
	configLib = import ./config.nix { inherit lib; };
	pathLib = import ./paths.nix { inherit lib; };
	abstractionsLib = import ../lib/abstractions.nix { inherit lib commandsLib pathLib typesLib configLib; };
in
{
	applications = {
		systemSettings = {
			general =  import ./options/applications/systemSettings/general.nix { inherit lib commandsLib; };
			appearance = import ./options/applications/systemSettings/appearance.nix { inherit lib commandsLib typesLib configLib pathLib; };
			controlCenter =  import ./options/applications/systemSettings/control-center.nix { inherit lib commandsLib; };
			desktopAndDock = import ./options/applications/systemSettings/desktop-and-dock.nix { inherit lib commandsLib typesLib configLib pathLib abstractionsLib; };
			spotlight = import ./options/applications/systemSettings/spotlight.nix { inherit lib commandsLib typesLib configLib pathLib abstractionsLib; };
			notifications = import ./options/applications/systemSettings/notifications.nix { inherit lib commandsLib typesLib configLib pathLib abstractionsLib; };
			sound = import ./options/applications/systemSettings/sound.nix { inherit lib commandsLib typesLib configLib pathLib abstractionsLib; };
			focus = import ./options/applications/systemSettings/focus.nix { inherit lib commandsLib typesLib configLib pathLib abstractionsLib; };
		};
		finder = import ./options/applications/finder.nix { inherit lib commandsLib configLib pathLib typesLib; };
	};
}
