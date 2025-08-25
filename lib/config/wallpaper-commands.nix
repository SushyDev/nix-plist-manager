{ lib, customLib, config }:
let
	nix-plist-manager = config.nix-plist-manager;
	users = nix-plist-manager.users;

	wallpaperPath = "/System/Library/Desktop Pictures/Solid Colors/Black.png";
	wallpaperCommands = lib.map (user: customLib.runAsUser user ("osascript -e 'tell application \"Finder\" to set the desktop picture to POSIX file \"${wallpaperPath}\"'")) users;
in wallpaperCommands
