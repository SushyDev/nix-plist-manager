# Renamed and removed options, kept out of the option files. Each entry makes evaluation
# fail (removed) or warn and forward (renamed) with a message pointing at the new option.
# Remove entries a release or two after they were added.
#
# Entries name the scope of the option: "user" (home-manager) or "system" (nix-darwin). Each
# module only declares the options of its own scope, so it only takes those entries.
{ scope }:
{ lib, ... }:
let
	prefix = [ "programs" "nix-plist-manager" "options" ];

	# renamed "user" [ "applications" "…" "old" ] [ "applications" "…" "new" ]
	renamed = optionScope: from: to:
		lib.optional (optionScope == scope) (lib.mkRenamedOptionModule (prefix ++ from) (prefix ++ to));

	# removed "user" [ "applications" "…" "old" ] "why, and what to use instead"
	removed = optionScope: path: reason:
		lib.optional (optionScope == scope) (lib.mkRemovedOptionModule (prefix ++ path) reason);
in
{
	imports = lib.concatLists [
	];
}
