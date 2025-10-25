{ lib, commandsLib, pathLib, typesLib, configLib, abstractionsLib }:
let
	byHostAppleDock = pathLib.generatePath true true "com.apple.dock";

	mkMapping = optionName: {
		"Mission Control" = {
			command = commandsLib.defaults.write byHostAppleDock optionName "int" "2";
		};
		"Application Windows" = {
			command = commandsLib.defaults.write byHostAppleDock optionName "int" "3";
		};
		"Desktop" = {
			command = commandsLib.defaults.write byHostAppleDock optionName "int" "4";
		};
		"Notification Center" = {
			command = commandsLib.defaults.write byHostAppleDock optionName "int" "12";
		};
		"Launchpad" = {
			command = commandsLib.defaults.write byHostAppleDock optionName "int" "11";
		};
		"Quick Note" = {
			command = commandsLib.defaults.write byHostAppleDock optionName "int" "14";
		};
		"Start Screen Saver" = {
			command = commandsLib.defaults.write byHostAppleDock optionName "int" "5";
		};
		"Disable Screen Saver" = {
			command = commandsLib.defaults.write byHostAppleDock optionName "int" "6";
		};
		"Put Display to Sleep" = {
			command = commandsLib.defaults.write byHostAppleDock optionName "int" "10";
		};
		"Lock Screen" = {
			command = commandsLib.defaults.write byHostAppleDock optionName "int" "13";
		};
		"Dashboard" = {
			command = commandsLib.defaults.write byHostAppleDock optionName "int" "7";
		};
		"-" = {
			command = commandsLib.defaults.write byHostAppleDock optionName "int" "1";
		};
	};
in
{
	topLeft = abstractionsLib.mkBasicMappingOption {
		path = [ "Desktop & Dock" "Hot Corners" "Top Left Corner" ];
		default = null;
		perUser = true;
		mapping = mkMapping "wvous-tl-corner";
	};
	topRight = abstractionsLib.mkBasicMappingOption {
		path = [ "Desktop & Dock" "Hot Corners" "Top Right Corner" ];
		default = null;
		perUser = true;
		mapping = mkMapping "wvous-tr-corner";
	};
	bottomLeft = abstractionsLib.mkBasicMappingOption {
		path = [ "Desktop & Dock" "Hot Corners" "Bottom Left Corner" ];
		default = null;
		perUser = true;
		mapping = mkMapping "wvous-bl-corner";
	};
	bottomRight = abstractionsLib.mkBasicMappingOption {
		path = [ "Desktop & Dock" "Hot Corners" "Bottom Right Corner" ];
		default = null;
		perUser = true;
		mapping = mkMapping "wvous-br-corner";
	};
}
