{ lib, customLib, config }:
let
	commands = import ../lib/config/main-mapping.nix { inherit lib customLib config; };
	spotlightCommands = import ../lib/config/spotlight-commands.nix { inherit lib customLib config; };
	wallpaperCommands = import ../lib/config/wallpaper-commands.nix { inherit lib customLib config; };
in
{
	system.activationScripts.defaults.text = ''
		# TODO pipe outputs to log file
		# TODO Figure out idiomatic log file for nix

		echo ${lib.escapeShellArg (lib.concatStringsSep "\n" commands)} > /Users/sushy/plist-manager-out.sh
		echo ${lib.escapeShellArg (lib.concatStringsSep "\n" spotlightCommands)} >> /Users/sushy/plist-manager-out.sh
		# echo ${lib.escapeShellArg (lib.concatStringsSep "\n" wallpaperCommands)} >> /Users/sushy/plist-manager-out.sh

		${lib.concatStringsSep "\n" commands}
		${lib.concatStringsSep "\n" spotlightCommands}
		# ${lib.concatStringsSep "\n" wallpaperCommands}

		killall Finder || true
		killall Dock || true
		killall SystemUIServer || true
	'';
}
