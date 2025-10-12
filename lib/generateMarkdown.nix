{ lib }:
let
	isOption = value: lib.isAttrs value && value ? description && value ? mapping && value ? option && value ? config;

	generateOptionMarkdown = option: path:
		let
			moduleType = if option.config.perUser then "home-manager" else "darwin";

			mkCommandRow = val: cmd: 
				let
					cmdStr = 
						if lib.isFunction cmd.command then "Dynamic command (depends on value. Please check source code)" 
						else cmd.command;
				in
				"`${val}`:\n```bash\n${cmdStr}\n```\n";

			name = "## ${option.description}\n\n";
			module = "**Module:** `${moduleType}`\n\n";
			description = "**Path:** `${path}`\n\n";
			valueDescription = "**Value Description:** `${option.option.type.description}`\n\n";
			values = "**Possible Values:**\n" + lib.concatStringsSep "\n" (lib.mapAttrsToList (val: cmd: "- `${val}`") option.mapping) + "\n\n";
			commands = "**Commands:**\n" + lib.concatStringsSep "\n" (lib.mapAttrsToList (val: cmd: mkCommandRow val cmd) option.mapping);
			separator = "\n---\n\n";
		in
		name + module + description + valueDescription + values + commands + separator;

	traverseOptions = options: currentPath:
		if isOption options then generateOptionMarkdown options currentPath
		else if lib.isAttrs options then
			let
				pathParts = lib.splitString "." currentPath;
				subPaths = lib.mapAttrsToList (name: value: traverseOptions value (if currentPath == "" then name else currentPath + "." + name)) options;
			in
			lib.concatStrings subPaths
		else "";

in
options: traverseOptions options ""
