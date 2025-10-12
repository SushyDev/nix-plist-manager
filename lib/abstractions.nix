{ lib, commandsLib, pathLib, typesLib, configLib }:
{
	mkBasicBoolOption = {
		description,
		default,
		perUser,
		unsetCommand,
		trueCommand,
		falseCommand,
	}: rec {
		inherit description default;

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
			perUser = perUser;
			command = configLib.commandNullOrBoolOrUnset mapping;
		};
	};

	mkBasicMappingOption = {
		description,
		default,
		perUser,
		mapping,
	}: rec {
		inherit description default;

		option = lib.mkOption {
			inherit description default;
			type = typesLib.nullOrMapping mapping;
		};

		config = {
			perUser = perUser;
			command = configLib.commandMapping mapping;
		};
	};
}
