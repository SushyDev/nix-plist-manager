{ lib, config, options }:
let
	buildOptionPath = optionsSet:
		lib.mapAttrs (name: value:
			if lib.isAttrs value then
				if value ? option then value.option
				else buildOptionPath value
			else value
		) optionsSet;
in
{
	nix-plist-manager = {
		enable = lib.mkOption {
			description = "Enable the plist manager program.";
			type = lib.types.bool;
			default = false;
		};

		options = buildOptionPath options;
	};
}

