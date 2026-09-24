{ lib }:
let
	isOption = value: lib.isAttrs value && value ? path && value ? mapping;

	renderCommand = cmd:
		if lib.isFunction cmd.command then cmd.command "value"
		else builtins.toString cmd.command;

	collect = attrPath: entries:
		lib.flatten (lib.mapAttrsToList (name: value:
			let
				currentPath = attrPath ++ [ name ];
			in
			if isOption value then [{
				option = lib.concatStringsSep "." currentPath;
				path = value.path;
				module = if value.config.perUser then "home-manager" else "darwin";
				type = value.option.type.description;
				commands = lib.mapAttrs (_: renderCommand) value.mapping;
			}]
			else if lib.isAttrs value then collect currentPath value
			else []
		) entries);
in
# Flat list of every option, consumed by tools/inventory to check off implemented settings
options: collect [] options
