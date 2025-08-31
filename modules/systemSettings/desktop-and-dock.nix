lib: customLib:
{
	dock = {
		size = 
			let
				minValue = 16;
				maxValue = 128;
			in
			lib.mkOption {
				description = "Desktop & Dock > Dock > Size";
				type = lib.types.nullOr (lib.types.ints.between minValue maxValue);
				default = null;
			};

		magnification = lib.mkOption {
			description = "Desktop & Dock > Dock > Magnification";
			type = lib.types.nullOr (lib.types.submodule {
				options = {
					enabled = lib.mkOption {
						description = "Enable Magnification";
						type = lib.types.nullOr lib.types.bool;
						default = null;
					};
					size = 
						let
							minValue = 30;
							maxValue = 128;
						in
						lib.mkOption {
							description = "Size when magnified";
							type = lib.types.nullOr (lib.types.ints.between minValue maxValue);
							default = null;
						};
				};
			});
			default = {};
		};

		positionOnScreen = 
			let
				mapping = {
					"Left" = "left";
					"Bottom" = "bottom";
					"Right" = "right";
				};
			in
			lib.mkOption {
				description = "Desktop & Dock > Dock > Position on screen";
				type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
				apply = value: if builtins.isNull value then null else mapping.${value};
				default = null;
			};

		minimizeWindowsUsing = 
			let
				mapping = {
					"Genie Effect" = "genie";
					"Scale Effect" = "scale";
				};
			in
			lib.mkOption {
				description = "Desktop & Dock > Dock > Minimize windows using";
				type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
				apply = value: if builtins.isNull value then null else mapping.${value};
				default = null;
			};

		doubleClickAWindowsTitleBarTo = 
			let
				mapping = {
					"Fill" = "fill";
					"Zoom" = "Maximize";
					"Minimize" = "minimize";
					"Do nothing" = "None";
				};
			in
			lib.mkOption {
				description = "Desktop & Dock > Dock > Double-click a window's title bar to";
				type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
				apply = value: if builtins.isNull value then null else mapping.${value};
				default = null;
			};

		minimizeWindowsIntoApplicationIcon = lib.mkOption {
			description = "Desktop & Dock > Dock > Minimize windows into application icon";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};

		automaticallyHideAndShowTheDock = lib.mkOption {
			description = "Desktop & Dock > Dock > Automatically hide and show the Dock";
			type = lib.types.nullOr (lib.types.submodule {
				options = {
					enabled = lib.mkOption {
						description = "Enable automatically hide and show the Dock";
						type = lib.types.nullOr lib.types.bool;
						default = null;
					};
					delay = lib.mkOption {
						description = "Delay before the Dock is shown when hovering over its position";
						type = lib.types.nullOr lib.types.float;
						default = null;
					};
					duration = lib.mkOption {
						description = "Duration of the animation when showing the Dock";
						type = lib.types.nullOr lib.types.float;
						default = null;
					};
				};
			});
			default = {};
		};

		animateOpeningApplications = lib.mkOption {
			description = "Desktop & Dock > Dock > Animate opening applications";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};

		showIndicatorsForOpenApplications = lib.mkOption {
			description = "Desktop & Dock > Dock > Show indicators for open applications";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};

		showSuggestedAndRecentAppsInDock = lib.mkOption {
			description = "Desktop & Dock > Dock > Show suggested and recent apps in Dock";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};

		persistentApps = lib.mkOption {
			type =
				let
					taggedType = lib.types.attrTag {
						app = lib.mkOption {
							description = "An application to be added to the dock.";
							type = lib.types.str;
						};
						file = lib.mkOption {
							description = "A file to be added to the dock.";
							type = lib.types.str;
						};
						folder = lib.mkOption {
							description = "A folder to be added to the dock.";
							type = lib.types.str;
						};
						spacer = lib.mkOption {
							description = "A spacer to be added to the dock. Can be small or regular size.";
							type = lib.types.submodule {
								options.small = lib.mkOption {
									description = "Whether the spacer is small.";
									type = lib.types.bool;
									default = false;
								};
							};
						};
					};

					simpleType = lib.types.either lib.types.str lib.types.path;
					toTagged = path: { app = path; };
				in
				lib.types.nullOr (lib.types.listOf (lib.types.coercedTo simpleType toTagged taggedType));
			default = null;
			example = [
				{ app = "/Applications/Safari.app"; }
				{ spacer = { small = false; }; }
				{ spacer = { small = true; }; }
				{ folder = "/System/Applications/Utilities"; }
				{ file = "/User/example/Downloads/test.csv"; }
			];
			description = ''Persistent applications, spacers, files, and folders in the dock.'';
			apply =
				let
					toTile = item: 
						if item ? app then {
							tile-data.file-data = {
								_CFURLString = item.app;
								_CFURLStringType = 0;
							};
						} else if item ? spacer then {
							tile-data = { };
							tile-type = if item.spacer.small then "small-spacer-tile" else "spacer-tile";
						} else if item ? folder then {
							tile-data.file-data = {
								_CFURLString = "file://" + item.folder;
								_CFURLStringType = 15;
							};
							tile-type = "directory-tile";
						} else if item ? file then {
							tile-data.file-data = {
								_CFURLString = "file://" + item.file;
								_CFURLStringType = 15;
							};
							tile-type = "file-tile";
						} else item;
				in
				value: if builtins.isNull value then null else map toTile value;
		};

		persistentOthers = lib.mkOption {
			type = lib.types.nullOr (lib.types.listOf (lib.types.either lib.types.path lib.types.str));
			default = null;
			example = [ "~/Documents" "~/Downloads" ];
			description = ''Persistent folders in the dock.'';
			apply = 
				let
					toTile = value:
						if !(lib.isList value) then value
						else lib.map (folder: {
								tile-data = {
									file-data = {
										_CFURLString = "file://" + folder;
										_CFURLStringType = 15; 
									}; 
								}; 
								tile-type = 
									if lib.strings.hasInfix "." (lib.last (lib.splitString "/" folder)) then "file-tile" 
									else "directory-tile"; 
							}) value;
				in
				value: if builtins.isNull value then null else toTile value;
		};

	};

	desktopAndStageManager = {
		showItems = lib.mkOption {
			description = "Desktop & Dock > Desktop & Stage Manager > Show Items";
			type = lib.types.nullOr (lib.types.submodule {
				options = {
					onDesktop = lib.mkOption {
						description = "On Desktop";
						type = lib.types.nullOr lib.types.bool;
						apply = value: if builtins.isNull value then null else if value == true then false else true;
						default = null;
					};
					inStageManager = lib.mkOption {
						description = "In Stage Manager";
						type = lib.types.nullOr lib.types.bool;
						apply = value: if builtins.isNull value then null else if value == true then false else true;
						default = null;
					};
				};
			});
			default = {};
		};

		clickWallpaperToRevealDesktop = 
			let
				mapping = {
					"Always" = true;
					"Only in Stage Manager" = false;
				};
			in	
			lib.mkOption {
				description = "Desktop & Dock > Desktop & Stage Manager > Click wallpaper to reveal desktop";
				type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
				apply = value: if builtins.isNull value then null else mapping.${value};
				default = null;
			};

		stageManager = lib.mkOption {
			description = "Desktop & Dock > Desktop & Stage Manager > Stage Manager";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};

		showRecentAppsInStageManager = lib.mkOption {
			description = "Desktop & Dock > Desktop & Stage Manager > Show recent apps in Stage Manager";
			type = lib.types.nullOr lib.types.bool;
			apply = value: if builtins.isNull value then null else if value == true then false else true;
			default = null;
		};

		showWindowsFromAnApplication = 
			let
				mapping = {
					"All at Once" = true;
					"One at a Time" = false;
				};
			in
			lib.mkOption {
				description = "Desktop & Dock > Desktop & Stage Manager > Show windows from an application";
				type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
				apply = value: if builtins.isNull value then null else mapping.${value};
				default = null;
			};
	};


#      StageManagerHideWidgets = 1;
#      StandardHideDesktopIcons = 1;
# -    StandardHideWidgets = 0;
# +    StandardHideWidgets = 1;

	widgets = {
		showWidgets = lib.mkOption {
			description = "Desktop & Dock > Widgets > Show Widgets";
			type = lib.types.nullOr (lib.types.submodule {
				options = {
					onDesktop = lib.mkOption {
						description = "On Desktop";
						type = lib.types.nullOr lib.types.bool;
						apply = value: if builtins.isNull value then null else if value == true then false else true;
						default = null;
					};
					inStageManager = lib.mkOption {
						description = "In Stage Manager";
						type = lib.types.nullOr lib.types.bool;
						apply = value: if builtins.isNull value then null else if value == true then false else true;
						default = null;
					};
				};
			});
			default = {};
		};

		widgetStyle = 
			let
				mapping = {
					"Automatic" = 2;
					"Monochrome" = 0;
					"Full-color" = 1;
				};
			in
			lib.mkOption {
				description = "Desktop & Dock > Widgets > Widget Style";
				type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
				apply = value: if builtins.isNull value then null else mapping.${value};
				default = null;
			};
		useIphoneWidgets = lib.mkOption {
			description = "Desktop & Dock > Widgets > Use iPhone Widgets";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
	};

	# defaultWebBrowser = # Not yet supported

	windows = {
		preferTabsWhenOpeningDocuments = 
			let
				mapping = {
					"Never" = "manual";
					"Always" = "always";
					"In Full Screen" = "fullscreen";
				};
			in
			lib.mkOption {
				description = "Desktop & Dock > Windows > Prefer tabs when opening documents";
				type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
				apply = value: if builtins.isNull value then null else mapping.${value};
				default = null;
			};
		askToKeepChangesWhenClosingDocuments = lib.mkOption {
			description = "Desktop & Dock > Windows > Ask to keep changes when closing documents";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
		closeWindowsWhenQuittingAnApplication = lib.mkOption {
			description = "Desktop & Dock > Windows > Close windows when quitting an application";
			apply = value: if builtins.isNull value then null else if value == true then false else true;
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
		dragWindowsToScreenEdgesToTile = lib.mkOption {
			description = "Desktop & Dock > Windows > Draw windows to the screen edges to tile";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
		dragWindowsToMenuBarToFillScreen = lib.mkOption {
			description = "Desktop & Dock > Windows > Drag windows to menu bar to fill screen";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
		holdOptionKeyWhileDraggingWindowsToTile = lib.mkOption {
			description = "Desktop & Dock > Windows > Hold Option key while dragging windows to tile";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
		tiledWindowsHaveMargin = lib.mkOption {
			description = "Desktop & Dock > Windows > Tiled windows have margin";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
	};
	missionControl = {
		automaticallyRearrangeSpacesBasedOnMostRecentUse = lib.mkOption {
			description = "Desktop & Dock > Mission Control > Automatically rearrange Spaces based on most recent use";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
		whenSwitchingToAnApplicationSwitchToAspaceWithOpenWindowsForTheApplication = lib.mkOption {
			description = "Desktop & Dock > Mission Control > When switching to an application, switch to a Space with open windows for the application";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
		groupWindowsByApplication = lib.mkOption {
			description = "Desktop & Dock > Mission Control > Group windows by application";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
		displaysHaveSeparateSpaces = lib.mkOption {
			description = "Desktop & Dock > Mission Control > Displays have separate Spaces";
			type = lib.types.nullOr lib.types.bool;
			apply = value: if builtins.isNull value then null else if value == true then false else true;
			default = null;
		};
		dragWindowsToTopOfScreenToEnterMissionControl = lib.mkOption {
			description = "Desktop & Dock > Mission Control > Drag windows to top of screen to enter Mission Control";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
	};
	# shortcuts = {} # Not yet supported
	hotCorners = 
		let
			mapping = {
				"Mission Control" = 2;
				"Application Windows" = 3;
				"Desktop" = 4;
				"Notification Center" = 12;
				"Launchpad" = 11;
				"Quick Note" = 14;
				"Start Screen Saver" = 5;
				"Disable Screen Saver" = 6;
				"Put Display To Sleep" = 10;
				"Lock Screen" = 13;
				"Dashboard" = 7;
				"-" = 1;
			};
		in
		{
			topLeft = lib.mkOption {
				description = "Desktop & Dock > Hot Corners > Top Left";
				type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
				apply = value: if builtins.isNull value then null else mapping.${value};
				default = null;
			};
			topRight = lib.mkOption {
				description = "Desktop & Dock > Hot Corners > Top Right";
				type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
				apply = value: if builtins.isNull value then null else mapping.${value};
				default = null;
			};
			bottomLeft = lib.mkOption {
				description = "Desktop & Dock > Hot Corners > Bottom Left";
				type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
				apply = value: if builtins.isNull value then null else mapping.${value};
				default = null;
			};
			bottomRight = lib.mkOption {
				description = "Desktop & Dock > Hot Corners > Bottom Right";
				type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
				apply = value: if builtins.isNull value then null else mapping.${value};
				default = null;
			};
		};
}
