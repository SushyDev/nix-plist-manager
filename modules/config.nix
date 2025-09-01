{ lib, customLib, config }:
let
	commands = import ../lib/config/main-mapping.nix { inherit lib customLib config; };
	spotlightCommands = import ../lib/config/spotlight-commands.nix { inherit lib customLib config; };
	wallpaperCommands = import ../lib/config/wallpaper-commands.nix { inherit lib customLib config; };
in
{
	# TODO pipe outputs to log file
	# TODO Figure out idiomatic log file for nix

	# Logging
	# echo ${lib.escapeShellArg (lib.concatStringsSep "\n" commands)} > /Users/sushy/plist-manager-out.sh
	# echo ${lib.escapeShellArg (lib.concatStringsSep "\n" spotlightCommands)} >> /Users/sushy/plist-manager-out.sh
	# echo ${lib.escapeShellArg (lib.concatStringsSep "\n" wallpaperCommands)} >> /Users/sushy/plist-manager-out.sh

	# TODO wallpaper code is disabled for now, only works for current user
	# ${lib.concatStringsSep "\n" wallpaperCommands}

	system.activationScripts.defaults.text = lib.mkAfter ''
		echo >&2 "nix-plist-manager..."
		${lib.concatStringsSep "\n" commands}
		${lib.concatStringsSep "\n" spotlightCommands}

		killall Finder || true
		killall Dock || true
		killall SystemUIServer || true
	'';
}
