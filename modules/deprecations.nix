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
		# labels System Settings changed on macOS 27
		(renamed "user"
			[ "applications" "systemSettings" "desktopAndDock" "windows" "dragWindowsToScreenEdgesToTile" ]
			[ "applications" "systemSettings" "desktopAndDock" "windows" "dragWindowsToLeftOrRightEdgeOfScreenToTile" ])
		(renamed "user"
			[ "applications" "systemSettings" "desktopAndDock" "windows" "tiledWindowsHaveMargin" ]
			[ "applications" "systemSettings" "desktopAndDock" "windows" "tiledWindowsHaveMargins" ])
	]
	# not menu bar controls on macOS 27: add them to Control Center and capture the layout
	++ lib.concatMap (module:
		removed "user" [ "applications" "systemSettings" "menuBar" module ] ''
			This is a Control Center control on macOS 27. Add it to Control Center, capture the layout with
			`nix run github:sushydev/nix-plist-manager#capture -- applications.systemSettings.menuBar.layout <directory>`
			and set applications.systemSettings.menuBar.layout to that directory.
		''
	) [ "stageManager" "accessibilityShortcuts" "musicRecognition" "hearing" ]
	++ renamed "user"
		[ "applications" "systemSettings" "menuBar" "batteryShowPercentage" ]
		[ "applications" "systemSettings" "menuBar" "batteryOptions" "showPercentage" ]
	++ removed "user" [ "applications" "systemSettings" "appleIntelligenceAndSiri" "siriResponses" ] ''
		macOS 27 offers "Spoken Response" and "Silent Response" only. Use
		applications.systemSettings.appleIntelligenceAndSiri.siri.responses.
	'';
}
