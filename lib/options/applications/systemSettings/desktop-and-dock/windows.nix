{ lib, commandsLib, pathLib, typesLib, configLib, abstractionsLib }:
let
	byHostAppleWindowManager = pathLib.generatePath true true "com.apple.WindowManager";
	byHostGlobalPreferences = pathLib.generatePath true true "com.apple.preference.global";
in
{
	preferTabsWhenOpeningDocuments = abstractionsLib.mkBasicMappingOption {
		path = [ "System Settings" "Desktop & Dock" "Windows" "Prefer tabs when opening documents" ];
		default = null;
		perUser = true;
		mapping = 
			let
				optionName = "AppleWindowTabbingMode";
			in
			{
				"unset" = {
					command = commandsLib.defaults.delete byHostGlobalPreferences optionName;
				};
				"Never" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "manual";
				};
				"Always" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "always";
				};
				"In Full Screen" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "fullscreen";
				};
			};
	};
	askToKeepChangesWhenClosingDocuments =
		let
			optionName = "NSCloseAlwaysConfirmsChanges";
		in
		abstractionsLib.mkBasicBoolOption {
			path = [ "System Settings" "Desktop & Dock" "Windows" "Ask to keep changes when closing documents" ];
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostGlobalPreferences optionName;
			trueCommand = commandsLib.defaults.write byHostGlobalPreferences optionName "bool" "true";
			falseCommand = commandsLib.defaults.write byHostGlobalPreferences optionName "bool" "false";
		};
	closeWindowsWhenQuittingAnApplication =
		let
			optionName = "NSQuitAlwaysKeepsWindows";
		in
		abstractionsLib.mkBasicBoolOption {
			path = [ "System Settings" "Desktop & Dock" "Windows" "Close windows when quitting an application" ];
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostGlobalPreferences optionName;
			trueCommand = commandsLib.defaults.write byHostGlobalPreferences optionName "bool" "false";
			falseCommand = commandsLib.defaults.write byHostGlobalPreferences optionName "bool" "true";
		};
	dragWindowsToScreenEdgesToTile =
		let
			optionName = "EnableTilingByEdgeDrag";
		in
		abstractionsLib.mkBasicBoolOption {
			path = [ "System Settings" "Desktop & Dock" "Windows" "Drag windows to screen edges to tile" ];
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostAppleWindowManager optionName;
			trueCommand = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "true";
			falseCommand = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "false";
		};
	dragWindowsToMenuBarToFillScreen =
		let
			optionName = "EnableTopTilingByEdgeDrag";
		in
		abstractionsLib.mkBasicBoolOption {
			path = [ "System Settings" "Desktop & Dock" "Windows" "Drag windows to menu bar to fill screen" ];
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostAppleWindowManager optionName;
			trueCommand = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "true";
			falseCommand = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "false";
		};
	holdOptionKeyWhileDraggingWindowsToTile =
		let
			optionName = "EnableTilingOptionAccelerator";
		in
		abstractionsLib.mkBasicBoolOption {
			path = [ "System Settings" "Desktop & Dock" "Windows" "Hold Option key while dragging windows to tile" ];
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostAppleWindowManager optionName;
			trueCommand = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "true";
			falseCommand = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "false";
		};
	tiledWindowsHaveMargin = 
		let
			optionName = "EnableTiledWindowMargins";
		in
		abstractionsLib.mkBasicBoolOption {
			path = [ "System Settings" "Desktop & Dock" "Windows" "Tiled windows have margin" ];
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostAppleWindowManager optionName;
			trueCommand = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "true";
			falseCommand = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "false";
		};
}
