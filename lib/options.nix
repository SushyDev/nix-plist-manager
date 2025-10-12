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
		controlCenter =  import ./options/systemSettings/control-center.nix { inherit lib commandsLib; };
		appearance = import ./options/systemSettings/appearance.nix { inherit lib commandsLib typesLib configLib pathLib; };
		desktopAndDock = import ./options/systemSettings/desktop-and-dock.nix { inherit lib commandsLib typesLib configLib pathLib abstractionsLib; };

	};
	applications = {
		finder = import ./options/applications/finder.nix { inherit lib commandsLib configLib pathLib typesLib; };
	};
}
