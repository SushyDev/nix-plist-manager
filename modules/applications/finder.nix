lib: customLib:
{
	removeItemsFromTheTrashAfter30Days = lib.mkOption {
		description = "Finder > Advanced > Remove items from the Trash after 30 days";
		type = lib.types.nullOr lib.types.bool;
		default = null;
	};
}
