{ lib }:
let
	settingsLib = import ./settings { inherit lib; };
	isOption = settingsLib.isEntry;

	generateOptionMarkdown = option: path: name:
		let
			described = settingsLib.describe option;

			mkCommandRow = value: command: "`${value}`:\n```bash\n${command}\n```\n";

			storage = lib.optionalString (described ? storage) (
				"**Stored in:**\n\n" + lib.concatMapStrings (key:
					"- `${key.domain}`${lib.optionalString (key.key != null) " `${key.key}`"}${lib.optionalString key.byHost " (current host)"}\n"
				) described.storage + "\n"
			);

			header = "## ${lib.lists.last described.path}\n\n";
			thing = "${lib.concatStringsSep " > " described.path}\n\n";
			module = "**Option Module:** `${described.module}`\n\n";
			optionPath = "**Option Path:** `${lib.concatStringsSep "." path}.${name}`\n\n";
			valueDescription = "**Option Value Description:** `${described.type}`\n\n";
			commands = lib.concatStringsSep "\n" (lib.mapAttrsToList mkCommandRow described.commands);
			separator = "\n---\n\n";
		in
		header + thing + module + optionPath + valueDescription + storage + commands + separator;

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
