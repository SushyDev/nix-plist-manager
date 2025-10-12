{ lib }:
rec {
	unset = lib.types.enum ["unset"];

	nullOrBoolOrUnset = lib.types.nullOr (
		lib.types.either
			lib.types.bool
			unset
	);

	nullOrIntsBetweenOrUnset = minValue: maxValue: lib.types.nullOr (
		lib.types.either
			(lib.types.ints.between minValue maxValue)
			unset
	);

	nullOrFloatsBetweenOrUnset = minValue: maxValue: lib.types.nullOr (
		lib.types.either
			(lib.types.addCheck (lib.types.numbers.between minValue maxValue) lib.isFloat)
			unset
	);

	nullOrMapping = mapping: lib.types.nullOr (lib.types.enum (lib.attrNames mapping));

	# TODO rename to nullOrEnumOrUnset
	enumOrUnset = values: lib.types.nullOr (
		lib.types.either 
			(lib.types.enum values) 
			unset
	);

	# Submodule for bitmask options
	bitmaskSubmodule = mapping: lib.types.submodule {
		options = lib.mapAttrs (name: _: lib.mkOption {
			description = name;
			type = lib.types.nullOr lib.types.bool;
			default = null;
		}) mapping;
	};

	unsetOrBitmask = mapping: lib.types.nullOr (
		lib.types.either 
			(bitmaskSubmodule mapping)
			unset
	);
}
