{ lib, commandsLib, pathLib, typesLib, configLib, abstractionsLib }:
let
	appleDock = pathLib.generatePath false true "com.apple.dock";

	byHostGlobalPreferences = pathLib.generatePath true true ".GlobalPreferences";
	byHostAppleDock = pathLib.generatePath true true "com.apple.dock";
	byHostAppleWindowManager = pathLib.generatePath true true "com.apple.WindowManager";
	byHostAppleWidgets = pathLib.generatePath true true "com.apple.widgets";
	byHostAppleChronod = pathLib.generatePath true true "com.apple.chronod";
	byHostAppleSpaces = pathLib.generatePath true true "com.apple.spaces";
in
{
	dock = {
		size = rec {
			description = "Desktop & Dock > Dock > Size";

			mapping = {
				"unset" = {
					command = lib.concatStrings [ 
						(commandsLib.defaults.delete byHostAppleDock "tilesize")
						commandsLib.chainOnSuccess
						(commandsLib.killall "Dock")
					];

				};
				"value" = {
					command = value: lib.concatStrings [
						(commandsLib.defaults.write byHostAppleDock "tilesize" "int" "${toString value}")
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
			enabled = abstractionsLib.mkBasicBoolOption {
				description = "Desktop & Dock > Dock > Magnification";
				default = null;
				perUser = true;
				unsetCommand = lib.concatStrings [ 
					(commandsLib.defaults.delete byHostAppleDock "magnification")
					commandsLib.chainOnSuccess
					(commandsLib.killall "Dock")
				];
				trueCommand = lib.concatStrings [
					(commandsLib.defaults.write byHostAppleDock "magnification" "bool" "true")
					commandsLib.chainOnSuccess
					(commandsLib.killall "Dock")
				];
				falseCommand = lib.concatStrings [
					(commandsLib.defaults.write byHostAppleDock "magnification" "bool" "false")
					commandsLib.chainOnSuccess
					(commandsLib.killall "Dock")
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
								commandsLib.chainOnSuccess
								(commandsLib.killall "Dock")
							];
						};
						"value" = {
							command = value: lib.concatStrings [
								(commandsLib.defaults.write byHostAppleDock  optionName "int" "${toString value}")
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
							commandsLib.chainOnSuccess
							(commandsLib.killall "Dock")
						];
					};
					"Left" = {
						command = lib.concatStrings [
							(commandsLib.defaults.write byHostAppleDock  optionName "string" "left")
							commandsLib.chainOnSuccess
							(commandsLib.killall "Dock")
						];
					};
					"Bottom" = {
						command = lib.concatStrings [
							(commandsLib.defaults.write byHostAppleDock optionName "string" "bottom")
							commandsLib.chainOnSuccess
							(commandsLib.killall "Dock")
						];
					};
					"Right" = {
						command = lib.concatStrings [
							(commandsLib.defaults.write byHostAppleDock optionName "string" "right")
							commandsLib.chainOnSuccess
							(commandsLib.killall "Dock")
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
						command = lib.concatStrings [ 
							(commandsLib.defaults.delete byHostAppleDock optionName)
							commandsLib.chainOnSuccess
							(commandsLib.killall "Dock")
						];
					};
					"Genie Effect" = {
						command = lib.concatStrings [
							(commandsLib.defaults.write byHostAppleDock optionName "string" "genie")
							commandsLib.chainOnSuccess
							(commandsLib.killall "Dock")
						];
					};
					"Scale Effect" = {
						command = lib.concatStrings [
							(commandsLib.defaults.write byHostAppleDock optionName "string" "scale")
							commandsLib.chainOnSuccess
							(commandsLib.killall "Dock")
						];
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
						command = lib.concatStrings [ 
							(commandsLib.defaults.delete byHostGlobalPreferences optionName)
							commandsLib.chainOnSuccess
							(commandsLib.killall "Dock")
						];
					};
					"Fill" = {
						command = lib.concatStrings [
							(commandsLib.defaults.write byHostGlobalPreferences optionName "string" "Fill")
							commandsLib.chainOnSuccess
							(commandsLib.killall "Dock")
						];
					};
					"Zoom" = {
						command = lib.concatStrings [
							(commandsLib.defaults.write byHostGlobalPreferences optionName "string" "Maximize")
							commandsLib.chainOnSuccess
							(commandsLib.killall "Dock")
						];
					};
					"Minimize" = {
						command = lib.concatStrings [
							(commandsLib.defaults.write byHostGlobalPreferences optionName "string" "Minimize")
							commandsLib.chainOnSuccess
							(commandsLib.killall "Dock")
						];
					};
					"Do nothing" = {
						command = lib.concatStrings [
							(commandsLib.defaults.write byHostGlobalPreferences optionName "string" "None")
							commandsLib.chainOnSuccess
							(commandsLib.killall "Dock")
						];
					};
				};
		};
		minimizeWindowsIntoApplicationIcon = abstractionsLib.mkBasicBoolOption {
			description = "Desktop & Dock > Dock > Minimize windows into application icon";
			default = null;
			perUser = true;
			unsetCommand = lib.concatStrings [ 
				(commandsLib.defaults.delete byHostAppleDock "minimize-to-application")
				commandsLib.chainOnSuccess
				(commandsLib.killall "Dock")
			];
			trueCommand = lib.concatStrings [
				(commandsLib.defaults.write byHostAppleDock "minimize-to-application" "bool" "true")
				commandsLib.chainOnSuccess
				(commandsLib.killall "Dock")
			];
			falseCommand = lib.concatStrings [
				(commandsLib.defaults.write byHostAppleDock "minimize-to-application" "bool" "false")
				commandsLib.chainOnSuccess
				(commandsLib.killall "Dock")
			];
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
		animateOpeningApplications = abstractionsLib.mkBasicBoolOption {
			description = "Desktop & Dock > Dock > Animate opening applications";
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostAppleDock "launchanim";
			trueCommand = commandsLib.defaults.write byHostAppleDock "launchanim" "bool" "true";
			falseCommand = commandsLib.defaults.write byHostAppleDock "launchanim" "bool" "false";
		};
		showIndicatorsForOpenApplications = abstractionsLib.mkBasicBoolOption {
			description = "Desktop & Dock > Dock > Show indicators for open applications";
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostAppleDock "show-process-indicators";
			trueCommand = commandsLib.defaults.write byHostAppleDock "show-process-indicators" "bool" "true";
			falseCommand = commandsLib.defaults.write byHostAppleDock "show-process-indicators" "bool" "false";
		};
		showSuggestedAndRecentAppsInDock = abstractionsLib.mkBasicBoolOption {
			description = "Desktop & Dock > Dock > Show suggested and recent apps in Dock";
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostAppleDock "show-recents";
			trueCommand = commandsLib.defaults.write byHostAppleDock "show-recents" "bool" "true";
			falseCommand = commandsLib.defaults.write byHostAppleDock "show-recents" "bool" "false";
		};

		#persistentApps
		#persistentOthers
	};

	desktopAndStageManager = {
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
	};
	widgets = {
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
	};
	windows = {
		preferTabsWhenOpeningDocuments = abstractionsLib.mkBasicMappingOption {
			description = "Desktop & Dock > Windows > Prefer tabs when opening documents";
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
				description = "Desktop & Dock > Windows > Ask to keep changes when closing documents";
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
				description = "Desktop & Dock > Windows > Close windows when quitting an application";
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
				description = "Desktop & Dock > Windows > Drag windows to screen edges to tile";
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
				description = "Desktop & Dock > Windows > Drag windows to menu bar to fill screen";
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
				description = "Desktop & Dock > Windows > Hold Option key while dragging windows to tile";
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
				description = "Desktop & Dock > Windows > Tiled windows have margin";
				default = null;
				perUser = true;
				unsetCommand = commandsLib.defaults.delete byHostAppleWindowManager optionName;
				trueCommand = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "true";
				falseCommand = commandsLib.defaults.write byHostAppleWindowManager optionName "bool" "false";
			};
	};
	missionControl = {
		automaticallyRearrangeSpacesBasedOnMostRecentUse =
			let
				optionName = "mru-spaces";
			in
			abstractionsLib.mkBasicBoolOption {
				description = "Desktop & Dock > Mission Control > Automatically rearrange Spaces based on most recent use";
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
				description = "Desktop & Dock > Mission Control > When switching to an application, switch to a Space with open windows for the application";
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
				description = "Desktop & Dock > Mission Control > Group windows by application";
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
				description = "Desktop & Dock > Mission Control > Displays have separate Spaces";
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
				description = "Desktop & Dock > Mission Control > Drag windows to top of screen to enter Mission Control";
				default = null;
				perUser = true;
				unsetCommand = commandsLib.defaults.delete appleDock optionName;
				trueCommand = commandsLib.defaults.write appleDock optionName "bool" "true";
				falseCommand = commandsLib.defaults.write appleDock optionName "bool" "false";
			};
	};
	hotCorners = 
		let
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
				description = "Desktop & Dock > Hot Corners > Top Left Corner";
				default = null;
				perUser = true;
				mapping = mkMapping "wvous-tl-corner";
			};
			topRight = abstractionsLib.mkBasicMappingOption {
				description = "Desktop & Dock > Hot Corners > Top Right Corner";
				default = null;
				perUser = true;
				mapping = mkMapping "wvous-tr-corner";
			};
			bottomLeft = abstractionsLib.mkBasicMappingOption {
				description = "Desktop & Dock > Hot Corners > Bottom Left Corner";
				default = null;
				perUser = true;
				mapping = mkMapping "wvous-bl-corner";
			};
			bottomRight = abstractionsLib.mkBasicMappingOption {
				description = "Desktop & Dock > Hot Corners > Bottom Right Corner";
				default = null;
				perUser = true;
				mapping = mkMapping "wvous-br-corner";
			};
		};
}
