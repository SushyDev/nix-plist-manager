{ lib, customLib, config }:
{
	nix-plist-manager = {
		enable = lib.mkOption {
			type = lib.types.bool;
			default = false;
			description = "Enable the plist manager configuration.";
		};

		users = lib.mkOption {
			type = lib.types.listOf lib.types.str;
			default = null;
			description = "The users for whom the plist manager is configured.";
		};

		systemSettings = {
			general = import ./systemSettings/general.nix lib customLib;
			appearance = import ./systemSettings/appearance.nix lib customLib;
			controlCenter = import ./systemSettings/control-center.nix lib customLib;
			desktopAndDock = import ./systemSettings/desktop-and-dock.nix lib customLib;
			spotlight = import ./systemSettings/spotlight.nix lib customLib;
			notifications = import ./systemSettings/notifications.nix lib customLib;
			sound = import ./systemSettings/sound.nix lib customLib;
			focus = import ./systemSettings/focus.nix lib customLib;
			keyboard = import ./systemSettings/keyboard.nix lib customLib;
			trackpad = import ./systemSettings/trackpad.nix lib customLib;
		};

		finder = import ./applications/finder.nix lib customLib;
	};
}
