{ lib, commandsLib, pathLib, typesLib, configLib, abstractionsLib }:
let
	byHostGlobalPreferences = pathLib.generatePath true true ".GlobalPreferences";
	byHostAppleDock = pathLib.generatePath true true "com.apple.dock";
in
{
	size = rec {
		description = "Desktop & Dock > Dock > Size";

		mapping = 
			let
				optionName = "tilesize";
			in
			{
				"unset" = {
					command = lib.concatStrings [ 
						(commandsLib.defaults.delete byHostAppleDock optionName)
						commandsLib.chainOnSuccess (commandsLib.killall "Dock")
					];

				};
				"value" = {
					command = value: lib.concatStrings [
						(commandsLib.defaults.write byHostAppleDock optionName "int" "${toString value}")
						commandsLib.chainOnSuccess (commandsLib.killall "Dock")
					];
				};
			};

		default = null;

		option = lib.mkOption {
			inherit description default;
			type = 
				let
					minValue = 16;
					maxValue = 128;
				in
				typesLib.nullOrIntsBetweenOrUnset minValue maxValue;
		};

		config = {
			perUser = true;
			command = configLib.commandNullOrValueOrUnset mapping;
		};
	};
	magnification = {
		enabled = 
			let
				optionName = "magnification";
			in
			abstractionsLib.mkBasicBoolOption {
				description = "Desktop & Dock > Dock > Magnification";
				default = null;
				perUser = true;
				unsetCommand = lib.concatStrings [ 
					(commandsLib.defaults.delete byHostAppleDock optionName)
					commandsLib.chainOnSuccess (commandsLib.killall "Dock")
				];
				trueCommand = lib.concatStrings [
					(commandsLib.defaults.write byHostAppleDock optionName "bool" "true")
					commandsLib.chainOnSuccess (commandsLib.killall "Dock")
				];
				falseCommand = lib.concatStrings [
					(commandsLib.defaults.write byHostAppleDock  optionName "bool" "false")
					commandsLib.chainOnSuccess (commandsLib.killall "Dock")
				];
			};
		size = rec {
			description = "Desktop & Dock > Dock > Magnification Size";

			mapping = 
				let
					optionName = "largesize";
				in
				{
					"unset" = {
						command = lib.concatStrings [ 
							(commandsLib.defaults.delete byHostAppleDock optionName)
							commandsLib.chainOnSuccess (commandsLib.killall "Dock")
						];
					};
					"value" = {
						command = value: lib.concatStrings [
							(commandsLib.defaults.write byHostAppleDock  optionName "int" "${toString value}")
							commandsLib.chainOnSuccess (commandsLib.killall "Dock")
						];
					};
				};

			default = null;

			option = lib.mkOption {
				inherit description default;
				type = 
					let
						minValue = 30;
						maxValue = 128;
					in
					typesLib.nullOrIntsBetweenOrUnset minValue maxValue;
			};

			config = {
				perUser = true;
				command = configLib.commandNullOrValueOrUnset mapping;
			};
		};
	};
	positionOnScreen = abstractionsLib.mkBasicMappingOption {
		description = "Desktop & Dock > Dock > Position on screen";
		default = null;
		perUser = true;
		mapping = 
			let
				optionName = "orientation";
			in
			{
				"unset" = {
					command = lib.concatStrings [ 
						(commandsLib.defaults.delete byHostAppleDock optionName)
						commandsLib.chainOnSuccess (commandsLib.killall "Dock")
					];
				};
				"Left" = {
					command = lib.concatStrings [
						(commandsLib.defaults.write byHostAppleDock  optionName "string" "left")
						commandsLib.chainOnSuccess (commandsLib.killall "Dock")
					];
				};
				"Bottom" = {
					command = lib.concatStrings [
						(commandsLib.defaults.write byHostAppleDock optionName "string" "bottom")
						commandsLib.chainOnSuccess (commandsLib.killall "Dock")
					];
				};
				"Right" = {
					command = lib.concatStrings [
						(commandsLib.defaults.write byHostAppleDock optionName "string" "right")
						commandsLib.chainOnSuccess (commandsLib.killall "Dock")
					];
				};
			};
	};
	minimizeWindowsUsing = abstractionsLib.mkBasicMappingOption {
		description = "Desktop & Dock > Dock > Minimize windows using";
		default = null;
		perUser = true;
		mapping = 
			let
				optionName = "mineffect";
			in
			{
				"unset" = {
					command = commandsLib.defaults.delete byHostAppleDock optionName;
				};
				"Genie Effect" = {
					command = commandsLib.defaults.write byHostAppleDock optionName "string" "genie";
				};
				"Scale Effect" = {
					command = commandsLib.defaults.write byHostAppleDock optionName "string" "scale";
				};
			};
	};
	doubleClickAWindowsTitleBarTo = abstractionsLib.mkBasicMappingOption {
		description = "Desktop & Dock > Dock > Double-click a window's title bar to";
		default = null;
		perUser = true;
		mapping = 
			let
				optionName = "AppleActionOnDoubleClick";
			in
			{
				"unset" = {
					command = commandsLib.defaults.delete byHostGlobalPreferences optionName;
				};
				"Fill" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "Fill";
				};
				"Zoom" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "Maximize";
				};
				"Minimize" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "Minimize";
				};
				"Do nothing" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "None";
				};
			};
	};
	minimizeWindowsIntoApplicationIcon = abstractionsLib.mkBasicBoolOption {
		description = "Desktop & Dock > Dock > Minimize windows into application icon";
		default = null;
		perUser = true;
		unsetCommand = commandsLib.defaults.delete byHostAppleDock "minimize-to-application";
		trueCommand = commandsLib.defaults.write byHostAppleDock "minimize-to-application" "bool" "true";
		falseCommand = commandsLib.defaults.write byHostAppleDock "minimize-to-application" "bool" "false";
	};
	automaticallyHideAndShowTheDock = {
		enabled = abstractionsLib.mkBasicBoolOption {
			description = "Desktop & Dock > Dock > Automatically hide and show the Dock";
			default = null;
			perUser = true;
			unsetCommand = lib.concatStrings [ 
				(commandsLib.defaults.delete byHostAppleDock "autohide")
				commandsLib.chainOnSuccess
				(commandsLib.killall "Dock")
			];
			trueCommand = lib.concatStrings [
				(commandsLib.defaults.write byHostAppleDock "autohide" "bool" "true")
				commandsLib.chainOnSuccess
				(commandsLib.killall "Dock")
			];
			falseCommand = lib.concatStrings [
				(commandsLib.defaults.write byHostAppleDock "autohide" "bool" "false")
				commandsLib.chainOnSuccess
				(commandsLib.killall "Dock")
			];
		};
		delay = rec {
			description = "Desktop & Dock > Dock > Automatically hide and show the Dock > Delay";

			mapping = 
				let
					optionName = "autohide-delay";
				in
				{
					"unset" = {
						command = lib.concatStrings [ 
							(commandsLib.defaults.delete byHostAppleDock optionName)
							commandsLib.chainOnSuccess
							(commandsLib.killall "Dock")
						];
					};
					"value" = {
						command = value: lib.concatStrings [
							(commandsLib.defaults.write byHostAppleDock optionName "float" "${toString value}")
							commandsLib.chainOnSuccess
							(commandsLib.killall "Dock")
						];
					};
				};

			default = null;

			option = lib.mkOption {
				inherit description default;
				type = 
					let
						minValue = 0.0;
						maxValue = 5.0;
					in
					typesLib.nullOrFloatsBetweenOrUnset minValue maxValue;
			};

			config = {
				perUser = true;
				command = configLib.commandNullOrValueOrUnset mapping;
			};
		};
		duration = rec {
			description = "Desktop & Dock > Dock > Automatically hide and show the Dock > Animation duration";

			mapping = 
				let
					optionName = "autohide-time-modifier";
				in
				{
					"unset" = {
						command = lib.concatStrings [ 
							(commandsLib.defaults.delete byHostAppleDock optionName)
							commandsLib.chainOnSuccess
							(commandsLib.killall "Dock")
						];
					};
					"value" = {
						command = value: lib.concatStrings [
							(commandsLib.defaults.write byHostAppleDock optionName "float" "${toString value}")
							commandsLib.chainOnSuccess
							(commandsLib.killall "Dock")
						];
					};
				};

			default = null;

			option = lib.mkOption {
				inherit description default;
				type = 
					let
						minValue = 0.0;
						maxValue = 5.0;
					in
					typesLib.nullOrFloatsBetweenOrUnset minValue maxValue;
			};

			config = {
				perUser = true;
				command = configLib.commandNullOrValueOrUnset mapping;
			};
		};
	};
	animateOpeningApplications = 
		let
			optionName = "launchanim";
		in
		abstractionsLib.mkBasicBoolOption {
			description = "Desktop & Dock > Dock > Animate opening applications";
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostAppleDock optionName;
			trueCommand = commandsLib.defaults.write byHostAppleDock optionName "bool" "true";
			falseCommand = commandsLib.defaults.write byHostAppleDock optionName "bool" "false";
		};
	showIndicatorsForOpenApplications = 
		let
			optionName = "show-process-indicators";
		in
		abstractionsLib.mkBasicBoolOption {
			description = "Desktop & Dock > Dock > Show indicators for open applications";
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostAppleDock optionName;
			trueCommand = commandsLib.defaults.write byHostAppleDock optionName "bool" "true";
			falseCommand = commandsLib.defaults.write byHostAppleDock optionName "bool" "false";
		};
	showSuggestedAndRecentAppsInDock = 
		let
			optionName = "show-recents";
		in
		abstractionsLib.mkBasicBoolOption {
			description = "Desktop & Dock > Dock > Show suggested and recent apps in Dock";
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostAppleDock optionName;
			trueCommand = commandsLib.defaults.write byHostAppleDock  optionName "bool" "true";
			falseCommand = commandsLib.defaults.write byHostAppleDock optionName "bool" "false";
		};
	#persistentApps
	#persistentOthers
}
