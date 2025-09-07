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
						if builtins.isNull actualValue || value.config.perUser == false then []
						else [{
							name = lib.concatStringsSep "." currentPath;
							command = value.config.command actualValue;
							perUser = value.config.perUser;
							value = actualValue;
						}]
				else
					buildConfigCommands value currentPath
			) optionsSet;
		in
		lib.flatten commands;

	# Generate commands and extract just the command strings
	allCommands = buildConfigCommands options ["programs" "nix-plist-manager" "options"];
	commandStrings = map (cmd: cmd.command) allCommands;
	commandScript = lib.concatStringsSep "\n" commandStrings;
in
{
	home.activation."nix-plist-manager" = (lib.hm.dag.entryAfter ["writeBoundary"] ''
			echo >&2 "User plist configuration... $USER"

			echo "" > ${config.home.homeDirectory}/plist-manager-user-out.sh
			${lib.optionalString (commandScript != "") ''cat >> ${config.home.homeDirectory}/plist-manager-user-out.sh << 'PLIST_EOF' 
${commandScript} 
PLIST_EOF''}

			${lib.optionalString (commandScript != "") commandScript}
	'');
}
