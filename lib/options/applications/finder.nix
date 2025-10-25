{ lib, commandsLib, configLib, pathLib, typesLib }:
let
	globalPreferencesPath = pathLib.generatePath true false ".GlobalPreferences";
	finderPath = pathLib.generatePath true true "com.apple.finder";
	birdPath = pathLib.generatePath true true "com.apple.bird";
in
{
	settings = {
		general = {
			showTheseItemsOnTheDesktop = {
				hardDisks = rec {
					description = "";
					path = [ "Finder" "Settings" "General" "Show these items on the desktop" "Hard disks" ];

					mapping = {
						"unset" = {
							command = commandsLib.defaults.delete finderPath "ShowHardDrivesOnDesktop";
						};
						"true" = {
							command = commandsLib.defaults.write finderPath "ShowHardDrivesOnDesktop" "bool" "true";
						};
						"false" = {
							command = commandsLib.defaults.write finderPath "ShowHardDrivesOnDesktop" "bool" "false";
						};
					};

					default = null;

					option = lib.mkOption {
						inherit description default;
						type = typesLib.nullOrBoolOrUnset;
					};

					config = {
						perUser = true;
						command = configLib.commandNullOrBoolOrUnset mapping;
					};
				};

				externalDisks = rec {
					description = "";
					path = [ "Finder" "Settings" "General" "Show these items on the desktop" "External disks" ];

					mapping = {
						"unset" = {
							command = commandsLib.defaults.delete finderPath "ShowExternalHardDrivesOnDesktop";
						};
						"true" = {
							command = commandsLib.defaults.write finderPath "ShowExternalHardDrivesOnDesktop" "bool" "true";
						};
						"false" = {
							command = commandsLib.defaults.write finderPath "ShowExternalHardDrivesOnDesktop" "bool" "false";
						};
					};

					default = null;

					option = lib.mkOption {
						inherit description default;
						type = typesLib.nullOrBoolOrUnset;
					};

					config = {
						perUser = true;
						command = configLib.commandNullOrBoolOrUnset mapping;
					};
				};

				cdsDvdsAndiPods = rec {
					description = "";
					path = [ "Finder" "Settings" "General" "Show these items on the desktop" "CDs, DVDs, and iPods" ];

					mapping = {
						"unset" = {
							command = commandsLib.defaults.delete finderPath "ShowRemovableMediaOnDesktop";
						};
						"true" = {
							command = commandsLib.defaults.write finderPath "ShowRemovableMediaOnDesktop" "bool" "true";
						};
						"false" = {
							command = commandsLib.defaults.write finderPath "ShowRemovableMediaOnDesktop" "bool" "false";
						};
					};

					default = null;

					option = lib.mkOption {
						inherit description default;
						type = typesLib.nullOrBoolOrUnset;
					};

					config = {
						perUser = true;
						command = configLib.commandNullOrBoolOrUnset mapping;
					};
				};

				connectedServers = rec {
					description = "";
					path = [ "Finder" "Settings" "General" "Show these items on the desktop" "Connected servers" ];

					mapping = {
						"unset" = {
							command = commandsLib.defaults.delete finderPath "ShowMountedServersOnDesktop";
						};
						"true" = {
							command = commandsLib.defaults.write finderPath "ShowMountedServersOnDesktop" "bool" "true";
						};
						"false" = {
							command = commandsLib.defaults.write finderPath "ShowMountedServersOnDesktop" "bool" "false";
						};
					};

					default = null;

					option = lib.mkOption {
						inherit description default;
						type = typesLib.nullOrBoolOrUnset;
					};

					config = {
						perUser = true;
						command = configLib.commandNullOrBoolOrUnset mapping;
					};
				};
			};
			# newFinderWindowsShow
			# syncDesktopAndDocumentsFolders
			openFoldersInTabsInsteadOfNewWindows = rec {
				path = [ "Finder" "Settings" "General" "Open folders in tabs instead of new windows" ];
				description = "";

				mapping = {
					"unset" = {
						command = commandsLib.defaults.delete finderPath "FinderSpawnTab";
					};
					"true" = {
						command = commandsLib.defaults.write finderPath "FinderSpawnTab" "bool" "true";
					};
					"false" = {
						command = commandsLib.defaults.write finderPath "FinderSpawnTab" "bool" "false";
					};
				};

				default = null;

				option = lib.mkOption {
					inherit description default;
					type = typesLib.nullOrBoolOrUnset;
				};

				config = {
					perUser = true;
					command = configLib.commandNullOrBoolOrUnset mapping;
				};
			};
		};
		sidebar = {
			recentTags = rec {
				path = [ "Finder" "Settings" "Sidebar" "Show Recent Tags" ];
				description = "";

				mapping = {
					"unset" = {
						command = commandsLib.defaults.delete finderPath "ShowRecentTags";
					};
					"true" = {
						command = commandsLib.defaults.write finderPath "ShowRecentTags" "bool" "true";
					};
					"false" = {
						command = commandsLib.defaults.write finderPath "ShowRecentTags" "bool" "false";
					};
				};

				default = null;

				option = lib.mkOption {
					inherit description default;
					type = typesLib.nullOrBoolOrUnset;
				};

				config = {
					perUser = true;
					command = configLib.commandNullOrBoolOrUnset mapping;
				};
			};
		};
		advanced = {
			showAllFilenameExtensions = rec {
				path = [ "Finder" "Settings" "Advanced" "Show all filename extensions" ];
				description = "";

				mapping = {
					"unset" = {
						command = commandsLib.defaults.delete globalPreferencesPath "AppleShowAllExtensions";
					};
					"true" = {
						command = commandsLib.defaults.write globalPreferencesPath "AppleShowAllExtensions" "bool" "true";
					};
					"false" = {
						command = commandsLib.defaults.write globalPreferencesPath "AppleShowAllExtensions" "bool" "false";
					};
				};

				default = null;

				option = lib.mkOption {
					inherit description default;
					type = typesLib.nullOrBoolOrUnset;
				};

				config = {
					perUser = true;
					command = configLib.commandNullOrBoolOrUnset mapping;
				};
			};

			showWarningBeforeChangingAnExtension = rec {
				path = [ "Finder" "Settings" "Advanced" "Show warning before changing an extension" ];
				description = "";

				mapping = {
					"unset" = {
						command = commandsLib.defaults.delete finderPath "FXEnableExtensionChangeWarning";
					};
					"true" = {
						command = commandsLib.defaults.write finderPath "FXEnableExtensionChangeWarning" "bool" "true";
					};
					"false" = {
						command = commandsLib.defaults.write finderPath "FXEnableExtensionChangeWarning" "bool" "false";
					};
				};

				default = null;

				option = lib.mkOption {
					inherit description default;
					type = typesLib.nullOrBoolOrUnset;
				};

				config = {
					perUser = true;
					command = configLib.commandNullOrBoolOrUnset mapping;
				};
			};

			showWarningBeforeRemovingFromiCloudDrive = rec {
				path = [ "Finder" "Settings" "Advanced" "Show warning before removing from iCloud Drive" ];
				description = "";

				mapping = {
					"unset" = {
						command = commandsLib.defaults.delete birdPath "FXEnableExtensionChangeWarning";
					};
					"true" = {
						command = commandsLib.defaults.write birdPath "FXEnableExtensionChangeWarning" "bool" "false";
					};
					"false" = {
						command = commandsLib.defaults.write birdPath "FXEnableExtensionChangeWarning" "bool" "true";
					};
				};

				default = null;

				option = lib.mkOption {
					inherit description default;
					type = typesLib.nullOrBoolOrUnset;
				};

				config = {
					perUser = true;
					command = configLib.commandNullOrBoolOrUnset mapping;
				};
			};

			showWarningBeforeEmptyingTheTrash = rec {
				path = [ "Finder" "Settings" "Advanced" "Show warning before emptying the Trash" ];
				description = "";

				mapping = 
					let
						optionName = "WarnOnEmptyTrash";
					in
					{
						"unset" = {
							command = commandsLib.defaults.delete finderPath optionName;
						};
						"true" = {
							command = commandsLib.defaults.write finderPath optionName "bool" "true";
						};
						"false" = {
							command = commandsLib.defaults.write finderPath optionName "bool" "false";
						};
					};

				default = null;

				option = lib.mkOption {
					inherit description default;
					type = typesLib.nullOrBoolOrUnset;
				};

				config = {
					perUser = true;
					command = configLib.commandNullOrBoolOrUnset mapping;
				};
			};

			removeItemsFromTheTrashAfter30Days = rec {
				path = [ "Finder" "Settings" "Advanced" "Remove items from the Trash after 30 days" ];
				description = "";

				mapping = 
					let
						optionName = "FXRemoveOldTrashItems";
					in
					{
						"unset" = {
							command = commandsLib.defaults.delete finderPath optionName;
						};
						"true" = {
							command = commandsLib.defaults.write finderPath optionName "bool" "true";
						};
						"false" = {
							command = commandsLib.defaults.write finderPath optionName "bool" "false";
						};
					};

				default = null;

				option = lib.mkOption {
					inherit description default;
					type = typesLib.nullOrBoolOrUnset;
				};

				config = {
					perUser = true;
					command = configLib.commandNullOrBoolOrUnset mapping;
				};
			};

			keepFoldersOnTop = {
				inWindowsWhenSortingByName = rec {
					path = [ "Finder" "Settings" "Advanced" "Keep folders on top" "In windows when sorting by name" ];
					description = "";

					mapping = 
						let
							optionName = "_FXSortFoldersFirst";
						in
						{
							"unset" = {
								command = commandsLib.defaults.delete finderPath optionName;
							};
							"true" = {
								command = commandsLib.defaults.write finderPath optionName "bool" "true";
							};
							"false" = {
								command = commandsLib.defaults.write finderPath optionName "bool" "false";
							};
						};

					default = null;

					option = lib.mkOption {
						inherit description default;
						type = typesLib.nullOrBoolOrUnset;
					};

					config = {
						perUser = true;
						command = configLib.commandNullOrBoolOrUnset mapping;
					};
				};
				onDesktop = rec {
					path = [ "Finder" "Settings" "Advanced" "Keep folders on top" "On Desktop" ];
					description = "";

					mapping = 
						let
							optionName = "_FXSortFoldersFirstOnDesktop";
						in
						{
							"unset" = {
								command = commandsLib.defaults.delete finderPath optionName;
							};
							"true" = {
								command = commandsLib.defaults.write finderPath optionName "bool" "true";
							};
							"false" = {
								command = commandsLib.defaults.write finderPath optionName "bool" "false";
							};
						};

					default = null;

					option = lib.mkOption {
						inherit description default;
						type = typesLib.nullOrBoolOrUnset;
					};

					config = {
						perUser = true;
						command = configLib.commandNullOrBoolOrUnset mapping;
					};
				};
			};

			whenPerformingASearch = rec {
				path = [ "Finder" "Settings" "Advanced" "When performing a search" ];
				description = "";

				mapping = 
					let
						optionName = "FXDefaultSearchScope";
					in
					{
						"unset" = {
							command = commandsLib.defaults.delete finderPath optionName;
						};
						"Search This Mac" = {
							command = commandsLib.defaults.write finderPath optionName "string" "SCev";
						};
						"Search the Current Folder" = {
							command = commandsLib.defaults.write finderPath optionName "string" "SCcf";
						};
						"Use the Previous Search Scope" = {
							command = commandsLib.defaults.write finderPath optionName "string" "SCsp";
						};
					};

				default = null;

				option = lib.mkOption {
					inherit description default;
					type = typesLib.nullOrMapping mapping;
				};

				config = {
					perUser = true;
					command = configLib.commandMapping mapping;
				};
			};
		};
	};
	menuBar = {
		view = {
			showTabBar = rec {
				path = [ "Finder" "Menu Bar" "View" "Show Tab Bar" ];
				description = "";

				mapping = 
					let
						optionName = "NSWindowTabbingShoudShowTabBarKey-com.apple.finder.TBrowserWindow";
					in
					{
						"unset" = {
							command = commandsLib.defaults.delete finderPath optionName;
						};
						"true" = {
							command = commandsLib.defaults.write finderPath optionName "bool" "true";
						};
						"false" = {
							command = commandsLib.defaults.write finderPath optionName "bool" "false";
						};
					};

				default = null;

				option = lib.mkOption {
					inherit description default;
					type = typesLib.nullOrBoolOrUnset;
				};

				config = {
					perUser = true;
					command = configLib.commandNullOrBoolOrUnset mapping;
				};
			};

			showSidebar = rec {
				path = [ "Finder" "Menu Bar" "View" "Show Sidebar" ];
				description = "";

				mapping = 
					let
						optionName = "ShowSidebar";
					in
					{
						"unset" = {
							command = commandsLib.defaults.delete finderPath optionName;
						};
						"true" = {
							command = commandsLib.defaults.write finderPath optionName "bool" "true";
						};
						"false" = {
							command = commandsLib.defaults.write finderPath optionName "bool" "false";
						};
					};

				default = null;

				option = lib.mkOption {
					inherit description default;
					type = typesLib.nullOrBoolOrUnset;
				};

				config = {
					perUser = true;
					command = configLib.commandNullOrBoolOrUnset mapping;
				};
			};

			showPathBar = rec {
				path = [ "Finder" "Menu Bar" "View" "Show Path Bar" ];
				description = "";

				mapping = 
					let
						optionName = "ShowPathBar";
					in
					{
						"unset" = {
							command = commandsLib.defaults.delete finderPath optionName;
						};
						"true" = {
							command = commandsLib.defaults.write finderPath optionName "bool" "true";
						};
						"false" = {
							command = commandsLib.defaults.write finderPath optionName "bool" "false";
						};
					};

				default = null;

				option = lib.mkOption {
					inherit description default;
					type = typesLib.nullOrBoolOrUnset;
				};

				config = {
					perUser = true;
					command = configLib.commandNullOrBoolOrUnset mapping;
				};
			};

			showStatusBar = rec {
				path = [ "Finder" "Menu Bar" "View" "Show Status Bar" ];
				description = "";

				mapping = 
					let
						optionName = "ShowStatusBar";
					in
					{
						"unset" = {
							command = commandsLib.defaults.delete finderPath optionName;
						};
						"true" = {
							command = commandsLib.defaults.write finderPath optionName "bool" "true";
						};
						"false" = {
							command = commandsLib.defaults.write finderPath optionName "bool" "false";
						};
					};

				default = null;

				option = lib.mkOption {
					inherit description default;
					type = typesLib.nullOrBoolOrUnset;
				};

				config = {
					perUser = true;
					command = configLib.commandNullOrBoolOrUnset mapping;
				};
			};
		};
	};
}
