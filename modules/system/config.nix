{ lib, config, options }:
let
	buildConfigCommands = optionsSet: configPath:
		let
			commands = lib.mapAttrsToList (name: value:
				let
					currentPath = configPath ++ [name];
				in
				if !lib.isAttrs value then []
				else if value ? option && value ? config then
					let
						pathExists = lib.hasAttrByPath currentPath config;
					in
					if !pathExists then []
					else
						let
							actualValue = lib.getAttrFromPath currentPath config;
						in
						if builtins.isNull actualValue then []
						else [{
							name = lib.concatStringsSep "." currentPath;
							command = value.config.command actualValue;
							perUser = value.config.perUser or false;
							value = actualValue;
						}]
				else
					buildConfigCommands value currentPath
			) optionsSet;
		in
		lib.flatten commands;

	# Generate commands and extract just the command strings
	allCommands = buildConfigCommands options ["nix-plist-manager" "options"];
	commandStrings = map (cmd: cmd.command) allCommands;
	commandScript = lib.concatStringsSep "\n" commandStrings;
in
{
	system.activationScripts.nixPlistManager.text = lib.mkAfter ''
		echo >&2 "nix-plist-manager..."
		echo "" > /Users/sushy/plist-manager-out.sh
		${lib.optionalString (commandScript != "") ''cat >> /Users/sushy/plist-manager-out.sh << 'PLIST_EOF' 
${commandScript} 
PLIST_EOF''}
		${lib.optionalString (commandScript != "") commandScript}
	'';
}

