lib: customLib:
{
	shareAcrossDevices = lib.mkOption {
		description = "Focus > Share across devices";
		type = lib.types.nullOr lib.types.bool;
		apply = value: if builtins.isNull value then null else if value then false else true;
		default = null;
	};
}
