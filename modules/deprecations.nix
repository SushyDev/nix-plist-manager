# Remove entries a release or two after they're added.
{ scope }:
{ lib, ... }:
let
	prefix = [ "programs" "nix-plist-manager" "options" ];

	renamed = optionScope: from: to:
		lib.optional (optionScope == scope) (lib.mkRenamedOptionModule (prefix ++ from) (prefix ++ to));

	removed = optionScope: path: reason:
		lib.optional (optionScope == scope) (lib.mkRemovedOptionModule (prefix ++ path) reason);
in
{
	imports = lib.concatLists [
		(renamed "user"
			[ "applications" "systemSettings" "desktopAndDock" "windows" "dragWindowsToScreenEdgesToTile" ]
			[ "applications" "systemSettings" "desktopAndDock" "windows" "dragWindowsToLeftOrRightEdgeOfScreenToTile" ])
		(renamed "user"
			[ "applications" "systemSettings" "desktopAndDock" "windows" "tiledWindowsHaveMargin" ]
			[ "applications" "systemSettings" "desktopAndDock" "windows" "tiledWindowsHaveMargins" ])
	]
	++ lib.concatMap (module:
		removed "user" [ "applications" "systemSettings" "menuBar" module ] ''
			This is a Control Center control on macOS 27. Add it to Control Center, capture the layout with
			`nix run github:sushydev/nix-plist-manager#capture -- applications.systemSettings.menuBar.layout <directory>`
			and set applications.systemSettings.menuBar.layout to that directory.
		''
	) [ "stageManager" "accessibilityShortcuts" "musicRecognition" "hearing" ]
	++ renamed "user"
		[ "applications" "systemSettings" "desktopAndDock" "widgets" "useIphoneWidgets" ]
		[ "applications" "systemSettings" "general" "airDropAndContinuity" "iPhoneWidgets" ]
	++ renamed "user"
		[ "applications" "systemSettings" "wallpaper" "wallpaper" ]
		[ "applications" "systemSettings" "wallpaper" "snapshot" ]
	++ renamed "user"
		[ "applications" "systemSettings" "menuBar" "batteryShowPercentage" ]
		[ "applications" "systemSettings" "menuBar" "batteryOptions" "showPercentage" ]
	++ removed "user" [ "applications" "systemSettings" "appleIntelligenceAndSiri" "siriResponses" ] ''
		macOS 27 offers "Spoken Response" and "Silent Response" only. Use
		applications.systemSettings.appleIntelligenceAndSiri.siri.responses.
	''
	++ renamed "system"
		[ "applications" "systemSettings" "general" "softwareUpdate" "automaticallyInstallSecurityResponseAndSystemFiles" ]
		[ "applications" "systemSettings" "general" "softwareUpdate" "automaticallyInstallSystemDataFilesAndSecurityUpdates" ];
}
