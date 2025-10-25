{ lib }:
let
	isOption = value: lib.isAttrs value && value ? path && value ? mapping;

	generateOptionMarkdown = option: path: name:
		let
			moduleType = if option.config.perUser then "home-manager" else "darwin";

			mkCommandRow = val: cmd: 
				let
					cmdStr = 
						if lib.isFunction cmd.command then cmd.command "value"
						else builtins.toString cmd.command;
				in
				"`${val}`:\n```bash\n${cmdStr}\n```\n";

			header = "## ${lib.lists.last option.path}\n\n";
			thing = "${lib.concatStringsSep " > " option.path}\n\n";
			module = "**Option Module:** `${moduleType}`\n\n";
			optionPath = "**Option Path:** `${lib.concatStringsSep "." path}.${name}`\n\n";
			valueDescription = "**Option Value Description:** `${option.option.type.description}`\n\n";
			commands = lib.concatStringsSep "\n" (lib.mapAttrsToList (val: cmd: mkCommandRow val cmd) option.mapping);
			separator = "\n---\n\n";
		in
		header + thing + module + optionPath + valueDescription + commands + separator;

	traverseOptions = options: currentPath:
		if isOption options then generateOptionMarkdown options currentPath
		else if lib.isAttrs options then
			let
				pathParts = lib.splitString "." currentPath;
				subPaths = lib.mapAttrsToList (name: value: traverseOptions value (if currentPath == "" then name else currentPath + "." + name)) options;
			in
			lib.concatStrings subPaths
		else "";

	markdownFiles = options:
		let
			isEmptySet = set: (builtins.attrNames set) == [];

			collect = (path: entries:
				let
					currentOptions = lib.filterAttrs (name: value: isOption value) entries;
					nestedEntries = lib.filterAttrs (name: value: lib.isAttrs value && !isOption value) entries;

					currentPath = lib.concatStringsSep "/" path;

					currentOptionsList = if !(isEmptySet currentOptions) then [{
						name = "/${currentPath}.md";
						value = 
							let
								starlight = "---\ntitle: ${lib.lists.last path}\n---\n\n";
								optionMarkdown = lib.concatStringsSep "\n" (lib.mapAttrsToList (optionName: optionValue:
									generateOptionMarkdown optionValue path optionName
								) currentOptions);
							in
							starlight + optionMarkdown;
					}] else [];

					nestedEntriesOptionsLists = if !(isEmptySet nestedEntries) then lib.flatten (lib.mapAttrsToList (name: value:
						collect (path ++ [ name ]) value
					) nestedEntries) else [];
				in
				currentOptionsList ++ nestedEntriesOptionsLists
			);
		in
		collect [] options;
in
markdownFiles
