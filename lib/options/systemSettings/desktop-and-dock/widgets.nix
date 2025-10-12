{ lib, commandsLib, pathLib, typesLib, configLib, abstractionsLib }:
let
	byHostAppleWidgets = pathLib.generatePath true true "com.apple.widgets";
	byHostAppleChronod = pathLib.generatePath true true "com.apple.chronod";
	byHostAppleWindowManager = pathLib.generatePath true true "com.apple.WindowManager";
in
{
	showWidgets = {
		onDesktop = 
			let
				optionName = "StandardHideWidgets";
			in
			abstractionsLib.mkBasicBoolOption {
				description = "Desktop & Dock > Widgets > Show widgets > On Desktop";
				default = null;
				perUser = true;
				unsetCommand = commandsLib.defaults.delete byHostAppleWindowManager "StandardShowWidgets";
				trueCommand = commandsLib.defaults.write byHostAppleWindowManager "StandardShowWidgets" "bool" "false";
				falseCommand = commandsLib.defaults.write byHostAppleWindowManager "StandardShowWidgets" "bool" "true";
			};
		inStageManager =
			let
				optionName = "StageManagerHideWidgets";
			in
			abstractionsLib.mkBasicBoolOption {
				description = "Desktop & Dock > Widgets > Show widgets > In Stage Manager";
				default = null;
				perUser = true;
				unsetCommand = commandsLib.defaults.delete byHostAppleWindowManager optionName;
				trueCommand = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "false";
				falseCommand = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "true";
			};
	};
	widgetStyle = abstractionsLib.mkBasicMappingOption {
		description = "Desktop & Dock > Widgets > Widget Style";
		default = null;
		perUser = true;
		mapping = 
			let
				optionName = "widgetAppearance";
			in
			{
				"unset" = {
					command = commandsLib.defaults.delete byHostAppleWidgets optionName;
				};
				"Automatic" = {
					command = commandsLib.defaults.write byHostAppleWidgets optionName "int" "2";
				};
				"Monochrome" = {
					command = commandsLib.defaults.write byHostAppleWidgets optionName "int" "0";
				};
				"Full-color" = {
					command = commandsLib.defaults.write byHostAppleWidgets optionName "int" "1";
				};
			};
	};
	useIphoneWidgets = 
		let
			optionName = "remoteWidgetsEnabled";
		in
		abstractionsLib.mkBasicBoolOption {
			description = "Desktop & Dock > Widgets > Use iPhone Widgets";
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostAppleChronod optionName;
			trueCommand = commandsLib.defaults.write byHostAppleChronod optionName "bool" "true";
			falseCommand = commandsLib.defaults.write byHostAppleChronod optionName "bool" "false";
		};
}
