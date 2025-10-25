{ lib, commandsLib, pathLib, typesLib, configLib, abstractionsLib }:
let
	appleDock = pathLib.generatePath true true "com.apple.dock";
	byHostAppleSpaces = pathLib.generatePath true false "com.apple.spaces";
	byHostGlobalPreferences = pathLib.generatePath true false "com.apple.preference.global";
in
{
	automaticallyRearrangeSpacesBasedOnMostRecentUse =
		let
			optionName = "mru-spaces";
		in
		abstractionsLib.mkBasicBoolOption {
			path = [ "Desktop & Dock" "Mission Control" "Automatically rearrange Spaces based on most recent use" ];
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete appleDock optionName;
			trueCommand = commandsLib.defaults.write appleDock optionName "bool" "true";
			falseCommand = commandsLib.defaults.write appleDock optionName "bool" "false";
		};
	whenSwitchingToAnApplicationSwitchToAspaceWithOpenWindowsForTheApplication =
		let
			optionName = "AppleSpacesSwitchOnActivate";
		in
		abstractionsLib.mkBasicBoolOption {
			path = [ "Desktop & Dock" "Mission Control" "When switching to an application, switch to a Space with open windows for the application" ];
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostGlobalPreferences optionName;
			trueCommand = commandsLib.defaults.write byHostGlobalPreferences optionName "bool" "true";
			falseCommand = commandsLib.defaults.write byHostGlobalPreferences optionName "bool" "false";
		};
	groupWindowsByApplication = 
		let
			optionName = "expose-group-apps";
		in
		abstractionsLib.mkBasicBoolOption {
			path = [ "Desktop & Dock" "Mission Control" "Group windows by application" ];
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete appleDock optionName;
			trueCommand = commandsLib.defaults.write appleDock optionName "bool" "true";
			falseCommand = commandsLib.defaults.write appleDock optionName "bool" "false";
		};
	displaysHaveSeparateSpaces =
		let
			optionName = "spans-displays";
		in
		abstractionsLib.mkBasicBoolOption {
			path = [ "Desktop & Dock" "Mission Control" "Displays have separate Spaces" ];
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostAppleSpaces optionName;
			trueCommand = commandsLib.defaults.write byHostAppleSpaces optionName "bool" "false";
			falseCommand = commandsLib.defaults.write byHostAppleSpaces optionName "bool" "true";
		};
	dragWindowsToTopOfScreenToEnterMissionControl =
		let
			optionName = "enterMissionControlByTopWindowDrag";
		in
		abstractionsLib.mkBasicBoolOption {
			path = [ "Desktop & Dock" "Mission Control" "Drag windows to top of screen to enter Mission Control" ];
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete appleDock optionName;
			trueCommand = commandsLib.defaults.write appleDock optionName "bool" "true";
			falseCommand = commandsLib.defaults.write appleDock optionName "bool" "false";
		};
}
