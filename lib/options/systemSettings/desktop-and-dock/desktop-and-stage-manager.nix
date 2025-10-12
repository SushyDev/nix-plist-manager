{ lib, commandsLib, pathLib, typesLib, configLib, abstractionsLib }:
let
	byHostAppleWindowManager = pathLib.generatePath true true "com.apple.WindowManager";
in
{
	showItems = {
		onDesktop = abstractionsLib.mkBasicBoolOption {
			description = "Desktop & Dock > Desktop & Stage Manager > Show Items > On Desktop";
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostAppleWindowManager "StandardHideDesktopIcons";
			trueCommand = commandsLib.defaults.write byHostAppleWindowManager "StandardHideDesktopIcons" "bool" "false";
			falseCommand = commandsLib.defaults.write byHostAppleWindowManager "StandardHideDesktopIcons" "bool" "true";
		};
		inStageManager = abstractionsLib.mkBasicBoolOption {
			description = "Desktop & Dock > Desktop & Stage Manager > Show Items > In Stage Manager";
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostAppleWindowManager "HideDesktop";
			trueCommand = commandsLib.defaults.write byHostAppleWindowManager "HideDesktop" "bool" "false";
			falseCommand = commandsLib.defaults.write byHostAppleWindowManager "HideDesktop" "bool" "true";
		};
	};
	clickWallpaperToRevealDesktop = abstractionsLib.mkBasicMappingOption {
		description = "Desktop & Dock > Desktop & Stage Manager > Click wallpaper to reveal desktop";
		default = null;
		perUser = true;
		mapping = 
			let
				optionName = "EnableStandardClickToShowDesktop";
			in
			{
				"unset" = {
					command = commandsLib.defaults.delete byHostAppleWindowManager optionName;
				};
				"Always" = {
					command = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "true";
				};
				"Only in Stage Manager" = {
					command = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "false";
				};
			};
	};
	stageManager = 
		let
			optionName = "GloballyEnabled";
		in
		abstractionsLib.mkBasicBoolOption {
			description = "Desktop & Dock > Desktop & Stage Manager > Stage Manager";
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostAppleWindowManager optionName;
			trueCommand = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "true";
			falseCommand = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "false";
		};
	showRecentAppsInStageManager = 
		let
			optionName = "AutoHide";
		in
		abstractionsLib.mkBasicBoolOption {
			description = "Desktop & Dock > Desktop & Stage Manager > Show recent apps in Stage Manager";
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostAppleWindowManager optionName;
			trueCommand = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "false";
			falseCommand = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "true";
		};
	showWindowsFromAnApplication = abstractionsLib.mkBasicMappingOption {
		description = "Desktop & Dock > Desktop & Stage Manager > Show windows from an application";
		default = null;
		perUser = true;
		mapping = 
			let
				optionName = "AppWindowGroupingBehavior";
			in
			{
				"unset" = {
					command = commandsLib.defaults.delete byHostAppleWindowManager optionName;
				};
				"All at Once" = {
					command = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "true";
				};
				"One at a Time" = {
					command = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "false";
				};
			};
	};
}
