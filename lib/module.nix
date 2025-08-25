{ lib, customLib, moduleName, constants }:
let
	/**
	 * Calculates the bitmask value based on the provided boolean options and their corresponding bit values.
	 *
	 * @param boolOptions An attribute set where keys are option names and values are booleans indicating whether the option is enabled.
	 * @param bitmaskMap An attribute set mapping option names to their respective bit values.
	 * @return The calculated bitmask value as an integer.
	 */
	calculateBitmaskValue = boolOptions: bitmaskMap:
		lib.foldl' builtins.bitOr 0 (lib.mapAttrsToList (name: value:
			if builtins.isNull boolOptions.${name} then 0
			else if boolOptions.${name} or false then value 
			else 0
		) bitmaskMap);

	getModuleName = name: "${moduleName} > ${name}";

	mapBoolModuleValue = value: onValue: offValue: if builtins.isNull value then null else if value then onValue else offValue;
	mapEnumModuleValue = value: if builtins.isNull value then null else constants.modules.${value};

	mkBoolModule = module: lib.mkOption {
		description = getModuleName module.name;
		apply = value: (mapBoolModuleValue value module.onValue module.offValue);
		type = lib.types.nullOr lib.types.bool;
		default = null;
	};

	mkEnumModule = displayName: lib.mkOption {
		description = getModuleName displayName;
		apply = mapEnumModuleValue;
		type = lib.types.nullOr (lib.types.enum (lib.attrNames constants.modules));
		default = null;
	};

	mkBitmapModule = module: lib.mkOption {
		description = getModuleName module.name;
		apply = value: (calculateBitmaskValue value module.mapping);
		type = lib.types.nullOr (lib.types.submodule {
			options = lib.mapAttrs (name: options: lib.mkOption {
				# TODO loop over paths to build this automatically
				description = "${moduleName} > ${module.name} > ${name}";
				type = lib.types.nullOr lib.types.bool;
				default = null;
			}) module.mapping;
		});
		default = null;
	};
in
{
	inherit mkBoolModule mkEnumModule mkBitmapModule;
}
