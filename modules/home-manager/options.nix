{ lib, config, options }:
let
	buildOptionPath = optionsSet:
		lib.mapAttrs (name: value:
			if lib.isAttrs value  then
				if value ? option && value ? config && value.config ? perUser && value.config.perUser == true then value.option
				else buildOptionPath value
			else value
		) optionsSet;
in
{
	programs.nix-plist-manager = {
		enable = lib.mkOption {
			type = lib.types.bool;
			default = false;
		};

		options = buildOptionPath options;
	};
}
