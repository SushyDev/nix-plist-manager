{ lib, customLib, config }:
let
	nix-plist-manager = config.nix-plist-manager;
	users = nix-plist-manager.users;

	mappings = user: {
		"/Library/Preferences" = {
			"com.apple.SoftwareUpdate" = {
				"AutomaticDownload" = nix-plist-manager.systemSettings.general.softwareUpdate.automaticallyDownloadNewUpdatesWhenAvailable;
				"AutomaticallyInstallMacOSUpdates" = nix-plist-manager.systemSettings.general.softwareUpdate.automaticallyInstallMacOSUpdates;
				"CriticalUpdateInstall" = nix-plist-manager.systemSettings.general.softwareUpdate.automaticallyInstallSecurityResponseAndSystemFiles;
			};
			"com.apple.commerce" = {
				"AutoUpdate" = nix-plist-manager.systemSettings.general.softwareUpdate.automaticallyInstallApplicationUpdatesFromTheAppStore;
			};
			"com.apple.CoreBrightness" = {
				"KeyboardBacklightABEnabled" = nix-plist-manager.systemSettings.keyboard.adjustKeyboardBrightnessInLowLight;
				"KeyboardBacklightManualBrightness" = nix-plist-manager.systemSettings.keyboard.keyboardBrightness;
				"KeyboardBacklightIdleDimTime" = nix-plist-manager.systemSettings.keyboard.turnKeyboardBacklightOffAfterInactivity;
			};
		};
		"~${user}/Library/Preferences" = {
			".GlobalPreferences" = {
				"com.apple.sound.beep.sound" = nix-plist-manager.systemSettings.sound.soundEffects.alertSound;
				"com.apple.sound.beep.volume" = nix-plist-manager.systemSettings.sound.soundEffects.alertVolume;
				"com.apple.sound.uiaudio.enabled" = nix-plist-manager.systemSettings.sound.soundEffects.playUserInterfaceSoundEffects;
				"com.apple.sound.beep.feedback" = nix-plist-manager.systemSettings.sound.soundEffects.playFeedbackWhenVolumeIsChanged;
				"KeyRepeat" = nix-plist-manager.systemSettings.keyboard.keyRepeatRate;
				"InitialKeyRepeat" = nix-plist-manager.systemSettings.keyboard.keyRepeatDelay;
				"AppleKeyboardUIMode" = nix-plist-manager.systemSettings.keyboard.keyboardNavigation;
				"com.apple.keyboard.fnState" = nix-plist-manager.systemSettings.keyboard.keyboardShortcuts.functionKeys.useF1F2EtcAsStandardFunctionKeys;
				"com.apple.trackpad.scaling" = nix-plist-manager.systemSettings.trackpad.trackingSpeed;
				"com.apple.trackpad.forceClick" = nix-plist-manager.systemSettings.trackpad.forceClickAndHapticFeedback;
				"AppleMenuBarVisibleInFullScreen" =
					let
						isEnabled = value:
							if value == 1 then false
							else if value == 2 then true
							else if value == 3 then false
							else if value == 4 then true
							else null;
					in
					isEnabled nix-plist-manager.systemSettings.controlCenter.automaticallyHideAndShowTheMenuBar;
				"_HIHideMenuBar" =
					let
						isEnabled = value:
							if value == 1 then true
							else if value == 2 then true
							else if value == 3 then false
							else if value == 4 then false
							else null;
					in
					isEnabled nix-plist-manager.systemSettings.controlCenter.automaticallyHideAndShowTheMenuBar;
				"AppleShowAllExtensions" = nix-plist-manager.applications.finder.settings.advanced.showAllFileExtensions;
			};
			"com.apple.dock" = {
				"enterMissionControlByTopWindowDrag" = nix-plist-manager.systemSettings.desktopAndDock.missionControl.dragWindowsToTopOfScreenToEnterMissionControl;
				"expose-group-apps" = nix-plist-manager.systemSettings.desktopAndDock.missionControl.groupWindowsByApplication;
				"mru-spaces" = nix-plist-manager.systemSettings.desktopAndDock.missionControl.automaticallyRearrangeSpacesBasedOnMostRecentUse;
			};
			"com.apple.ncprefs" = {
				"content_visibility" = nix-plist-manager.systemSettings.notifications.notificationCenter.showPreviews;
				"summarize_previews" = nix-plist-manager.systemSettings.notifications.notificationCenter.summarizeNotifications;
			};
			"com.apple.donotdisturbd" = {
				"disableCloudSync" = nix-plist-manager.systemSettings.focus.shareAcrossDevices;
			};
			"com.apple.HIToolbox" = {
				"AppleFnUsageType" = nix-plist-manager.systemSettings.keyboard.pressGlobeKeyTo;
			};
			"com.apple.assistant.support" = {
				"Dictation Enabled" = nix-plist-manager.systemSettings.keyboard.dictation.enabled;
			};
			"com.apple.AppleMultitouchTrackpad" = {
				"ForceClickSuppressed" = !nix-plist-manager.systemSettings.trackpad.forceClickAndHapticFeedback;
				"FirstClickThreshold" = nix-plist-manager.systemSettings.trackpad.click;
				"SecondClickThreshold" = nix-plist-manager.systemSettings.trackpad.click;
				"Clicking" = nix-plist-manager.systemSettings.trackpad.tapToClick;
			};
			"com.apple.AppleBluetoothMultitouch.trackpad" = {
				"FirstClickThreshold" = nix-plist-manager.systemSettings.trackpad.click;
				"SecondClickThreshold" = nix-plist-manager.systemSettings.trackpad.click;
				"Clicking" = nix-plist-manager.systemSettings.trackpad.tapToClick;
			};
		};
		"~${user}/Library/Preferences/ByHost" = {
			".GlobalPreferences" = {
				"AppleInterfaceStyle" = nix-plist-manager.systemSettings.appearance.appearance;
				"AppleAccentColor" = nix-plist-manager.systemSettings.appearance.accentColor;
				"NSTableViewDefaultSizeMode" = nix-plist-manager.systemSettings.appearance.sidebarIconSize;
				"AppleReduceDesktopTinting" = nix-plist-manager.systemSettings.appearance.allowWallpaperTintingInWindows;
				"AppleShowScrollBars" = nix-plist-manager.systemSettings.appearance.showScrollBars;
				"AppleScrollerPagingBehavior" = nix-plist-manager.systemSettings.appearance.clickInTheScrollBarTo;
				"AppleICUForce24HourTime" = nix-plist-manager.systemSettings.general.dateAndTime."24HourTime";
				"AppleActionOnDoubleClick" = nix-plist-manager.systemSettings.desktopAndDock.dock.doubleClickAWindowsTitleBarTo;
				"AppleWindowTabbingMode" = nix-plist-manager.systemSettings.desktopAndDock.windows.preferTabsWhenOpeningDocuments;
				"NSCloseAlwaysConfirmsChanges" = nix-plist-manager.systemSettings.desktopAndDock.windows.askToKeepChangesWhenClosingDocuments;
				"NSQuitAlwaysKeepsWindows" = nix-plist-manager.systemSettings.desktopAndDock.windows.closeWindowsWhenQuittingAnApplication;
				"AppleSpacesSwitchOnActivate" = nix-plist-manager.systemSettings.desktopAndDock.missionControl.whenSwitchingToAnApplicationSwitchToAspaceWithOpenWindowsForTheApplication;
			};
			"com.apple.controlcenter" = {
				"WiFi" = nix-plist-manager.systemSettings.controlCenter.wifi;
				"Bluetooth" = nix-plist-manager.systemSettings.controlCenter.bluetooth;
				"AirDrop" = nix-plist-manager.systemSettings.controlCenter.airdrop;
				"FocusModes" = nix-plist-manager.systemSettings.controlCenter.focusModes;
				"StageManager" = nix-plist-manager.systemSettings.controlCenter.stageManager;
				"ScreenMirroring" = nix-plist-manager.systemSettings.controlCenter.screenMirroring;
				"Display" = nix-plist-manager.systemSettings.controlCenter.display;
				"Sound" = nix-plist-manager.systemSettings.controlCenter.sound;
				"NowPlaying" = nix-plist-manager.systemSettings.controlCenter.nowPlaying;
				"AccessibilityShortcuts" = nix-plist-manager.systemSettings.controlCenter.accessibilityShortcuts;
				"Battery" = nix-plist-manager.systemSettings.controlCenter.battery;
				"BatteryShowPercentage" = nix-plist-manager.systemSettings.controlCenter.batteryShowPercentage;
				"MusicRecognition" = nix-plist-manager.systemSettings.controlCenter.musicRecognition;
				"Hearing" = nix-plist-manager.systemSettings.controlCenter.hearing;
				"UserSwitcher" = nix-plist-manager.systemSettings.controlCenter.fastUserSwitching;
				"KeyboardBrightness" = nix-plist-manager.systemSettings.controlCenter.keyboardBrightness;
			};
			"com.apple.dock" = {
				"tilesize" = nix-plist-manager.systemSettings.desktopAndDock.dock.size;
				"magnification" = nix-plist-manager.systemSettings.desktopAndDock.dock.magnification.enabled;
				"largesize" = nix-plist-manager.systemSettings.desktopAndDock.dock.magnification.size;
				"orientation" = nix-plist-manager.systemSettings.desktopAndDock.dock.positionOnScreen;
				"mineffect" = nix-plist-manager.systemSettings.desktopAndDock.dock.minimizeWindowsUsing;
				"minimize-to-application" = nix-plist-manager.systemSettings.desktopAndDock.dock.minimizeWindowsIntoApplicationIcon;
				"autohide" = nix-plist-manager.systemSettings.desktopAndDock.dock.automaticallyHideAndShowTheDock.enabled;
				"autohide-delay" = nix-plist-manager.systemSettings.desktopAndDock.dock.automaticallyHideAndShowTheDock.delay;
				"autohide-time-modifier" = nix-plist-manager.systemSettings.desktopAndDock.dock.automaticallyHideAndShowTheDock.duration;
				"launchanim" = nix-plist-manager.systemSettings.desktopAndDock.dock.animateOpeningApplications;
				"show-process-indicators" = nix-plist-manager.systemSettings.desktopAndDock.dock.showIndicatorsForOpenApplications;
				"show-recents" = nix-plist-manager.systemSettings.desktopAndDock.dock.showSuggestedAndRecentAppsInDock;
				"wvous-tl-corner" = nix-plist-manager.systemSettings.desktopAndDock.hotCorners.topLeft;
				"wvous-tr-corner" = nix-plist-manager.systemSettings.desktopAndDock.hotCorners.topRight;
				"wvous-bl-corner" = nix-plist-manager.systemSettings.desktopAndDock.hotCorners.bottomLeft;
				"wvous-br-corner" = nix-plist-manager.systemSettings.desktopAndDock.hotCorners.bottomRight;
				"persistent-apps" = nix-plist-manager.systemSettings.desktopAndDock.dock.persistentApps;
				"persistent-others" = nix-plist-manager.systemSettings.desktopAndDock.dock.persistentOthers;
			};
			"com.apple.WindowManager" = {
				"StandardHideDesktopIcons" = nix-plist-manager.systemSettings.desktopAndDock.desktopAndStageManager.showItems.onDesktop;
				"HideDesktop" = nix-plist-manager.systemSettings.desktopAndDock.desktopAndStageManager.showItems.inStageManager;
				"EnableStandardClickToShowDesktop" = nix-plist-manager.systemSettings.desktopAndDock.desktopAndStageManager.clickWallpaperToRevealDesktop;
				"GloballyEnabled" = nix-plist-manager.systemSettings.desktopAndDock.desktopAndStageManager.stageManager;
				"AutoHide" = nix-plist-manager.systemSettings.desktopAndDock.desktopAndStageManager.showRecentAppsInStageManager;
				"AppWindowGroupingBehavior" = nix-plist-manager.systemSettings.desktopAndDock.desktopAndStageManager.showWindowsFromAnApplication;
				"StageManagerHideWidgets" = nix-plist-manager.systemSettings.desktopAndDock.widgets.showWidgets.inStageManager;
				"StandardHideWidgets" = nix-plist-manager.systemSettings.desktopAndDock.widgets.showWidgets.onDesktop;
				"EnableTilingByEdgeDrag" = nix-plist-manager.systemSettings.desktopAndDock.windows.dragWindowsToScreenEdgesToTile;
				"EnableTopTilingByEdgeDrag" = nix-plist-manager.systemSettings.desktopAndDock.windows.dragWindowsToMenuBarToFillScreen;
				"EnableTilingOptionAccelerator" = nix-plist-manager.systemSettings.desktopAndDock.windows.holdOptionKeyWhileDraggingWindowsToTile;
				"EnableTiledWindowMargins" = nix-plist-manager.systemSettings.desktopAndDock.windows.tiledWindowsHaveMargin;
			};
			"com.apple.widgets" = {
				"widgetAppearance" = nix-plist-manager.systemSettings.desktopAndDock.widgets.widgetStyle;
			};
			"com.apple.chronod" = {
				"remoteWidgetsEnabled" = nix-plist-manager.systemSettings.desktopAndDock.widgets.useIphoneWidgets;
			};
			"com.apple.spaces" = {
				"spans-displays" = nix-plist-manager.systemSettings.desktopAndDock.missionControl.displaysHaveSeparateSpaces;
			};
			"com.apple.Spotlight" = {
				"MenuItemHidden" = nix-plist-manager.systemSettings.controlCenter.menuBarOnly.spotlight;
			};
			"com.apple.Siri" = {
				"StatusMenuVisible" = nix-plist-manager.systemSettings.controlCenter.menuBarOnly.siri;
			};
			"com.apple.assistant.support" = {
				"Search Queries Data Sharing Status" = nix-plist-manager.systemSettings.spotlight.helpAppleImproveSearch;
			};
			"com.apple.finder" = {
				"ShowHardDrivesOnDesktop" = nix-plist-manager.applications.finder.settings.general.showTheseItemsOnTheDesktop.hardDisks;
				"ShowExternalHardDrivesOnDesktop" = nix-plist-manager.applications.finder.settings.general.showTheseItemsOnTheDesktop.externalDisks;
				"ShowRemovableMediaOnDesktop" = nix-plist-manager.applications.finder.settings.general.showTheseItemsOnTheDesktop.cdsDvdsAndiPods;
				"ShowMountedServersOnDesktop" = nix-plist-manager.applications.finder.settings.general.showTheseItemsOnTheDesktop.connectedServers;
				"FinderSpawnTab" = nix-plist-manager.applications.finder.settings.general.openFoldersInNewTabsInsteadOfNewWindows;

				"ShowRecentTags" = nix-plist-manager.applications.finder.settings.sidebar.recentTags;

				"FXEnableExtensionChangeWarning" = nix-plist-manager.applications.finder.settings.advanced.showWarningBeforeChangingAnExtension;
				"WarnOnEmptyTrash" = nix-plist-manager.applications.finder.settings.advanced.showWarningBeforeEmptyingTheTrash;
				"FXRemoveOldTrashItems" = nix-plist-manager.applications.finder.settings.advanced.removeItemsFromTheTrashAfter30Days;
				"_FXSortFoldersFirst" = nix-plist-manager.applications.finder.settings.advanced.keepFoldersOnTop.inWindowsWhenShortingByName;
				"_FXSortFoldersFirstOnDesktop" = nix-plist-manager.applications.finder.settings.advanced.keepFoldersOnTop.onDesktop;
				"FXDefaultSearchScope" = nix-plist-manager.applications.finder.settings.advanced.whenPerformingASearch;

				"NSWindowTabbingShoudShowTabBarKey-com.apple.finder.TBrowserWindow" = nix-plist-manager.applications.finder.menuBar.view.showTabBar;
				"ShowSidebar" = nix-plist-manager.applications.finder.menuBar.view.showSidebar;
				"ShowPreviewPane" = nix-plist-manager.applications.finder.menuBar.view.showPreview;
				"ShowPathBar" = nix-plist-manager.applications.finder.menuBar.view.showPathBar;
				"ShowStatusBar" = nix-plist-manager.applications.finder.menuBar.view.showStatusBar;
			};
			"com.apple.bird.plist" = {
				"com.apple.clouddocs.unshared.moveOut.suppress" = !nix-plist-manager.applications.finder.settings.advanced.showWarningBeforeRemovingFromiCloudDrive;
			};
		};
	};

	defaultsWrite = domain: key: value: 
		let
			stringifyValue = value: 
				if lib.typeOf value == "bool" then lib.boolToString value 
				else builtins.toString value;

			valueType = value: 
				if lib.typeOf value == "list" then "array"
				else lib.typeOf value;
		in
		"defaults write ${domain} \"${key}\" ${lib.escapeShellArg (lib.generators.toPlist { escape = true; } value)}";

	defaultsWriteAsUser = user: domain: key: value: 
		let
		in
		customLib.runAsUser user (defaultsWrite domain key value);

	generateCommand = user: path: domainName: settingName: settingValue:
		let
			domain = "${path}/${domainName}";
		in
		if path == "/Library/Preferences"
			then (defaultsWrite domain settingName settingValue)
			else (defaultsWriteAsUser user domain settingName settingValue);

	isNotNull = attrs:
		lib.filterAttrs (name: value: !builtins.isNull value) attrs;

	forEachSettings = user: path: domainName: settings:
		lib.mapAttrsToList (settingName: settingValue: generateCommand user path domainName settingName settingValue) (isNotNull settings);

	forEachPath = user: path: domains:
		lib.mapAttrsToList (domainName: settings: forEachSettings user path domainName settings) (isNotNull domains);

	forEachMapping = user: mapping:
		lib.mapAttrsToList (path: domains: forEachPath user path domains) (isNotNull mapping);

	forEachUser = users:
		lib.map (user: forEachMapping user (mappings user)) users;
in lib.flatten (forEachUser users)
