{ lib, customLib, config }:
{
	nix-plist-manager = {
		enable = lib.mkOption {
			description = "Enable the plist manager configuration.";
			type = lib.types.bool;
			default = false;
		};

		users = lib.mkOption {
			description = "The users for whom the plist manager is configured.";
			type = lib.types.listOf lib.types.str;
			default = null;
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

		applications = {
			finder = import ./applications/finder.nix lib customLib;
		};
	};
}
