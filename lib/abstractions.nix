{ lib, commandsLib, pathLib, typesLib, configLib }:
{
	mkBasicBoolOption = {
		path,
		default,
		perUser,
		unsetCommand,
		trueCommand,
		falseCommand,
	}: rec {
		inherit path;

		description = "";

		mapping = {
			"unset" = {
				command = unsetCommand;
			};
			"true" = {
				command = trueCommand;
			};
			"false" = {
				command = falseCommand;
			};
		};

		option = lib.mkOption {
			inherit description default;
			type = typesLib.nullOrBoolOrUnset;
		};

		config = {
			inherit perUser;
			command = configLib.commandNullOrBoolOrUnset mapping;
		};
	};

	mkBasicMappingOption = {
		path,
		default,
		perUser,
		mapping,
	}: rec {
		inherit path mapping;

		description = "";

		option = lib.mkOption {
			inherit description default;
			type = typesLib.nullOrMapping mapping;
		};

		config = {
			inherit perUser;
			command = configLib.commandMapping mapping;
		};
	};
}
