{ lib }:
let
	commandsLib = import ./commands.nix { inherit lib; };
	typesLib = import ./types.nix { inherit lib; };
	configLib = import ./config.nix { inherit lib; };
	pathLib = import ./paths.nix { inherit lib; };
	abstractionsLib = import ../lib/abstractions.nix { inherit lib commandsLib pathLib typesLib configLib; };
in
{
	systemSettings = {
		general =  import ./options/systemSettings/general.nix { inherit lib commandsLib; };
		appearance = import ./options/systemSettings/appearance.nix { inherit lib commandsLib typesLib configLib pathLib; };
		controlCenter =  import ./options/systemSettings/control-center.nix { inherit lib commandsLib; };
		desktopAndDock = import ./options/systemSettings/desktop-and-dock.nix { inherit lib commandsLib typesLib configLib pathLib abstractionsLib; };
		spotlight = import ./options/systemSettings/spotlight.nix { inherit lib commandsLib typesLib configLib pathLib abstractionsLib; };
		notifications = import ./options/systemSettings/notifications.nix { inherit lib commandsLib typesLib configLib pathLib abstractionsLib; };
		sound = import ./options/systemSettings/sound.nix { inherit lib commandsLib typesLib configLib pathLib abstractionsLib; };
		focus = import ./options/systemSettings/focus.nix { inherit lib commandsLib typesLib configLib pathLib abstractionsLib; };
	};
	applications = {
		finder = import ./options/applications/finder.nix { inherit lib commandsLib configLib pathLib typesLib; };
	};
}
