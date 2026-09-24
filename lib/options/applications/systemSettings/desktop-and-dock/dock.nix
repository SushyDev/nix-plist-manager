{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user global stored bool number enum snapshot restarts restartsDiscardingItsState implies shows;

	pane = "com.apple.settings.desktopAndDock";
	option = name: "applications.systemSettings.desktopAndDock.dock.${name}";

	dock = name: user "com.apple.dock" name;
	restartsDock = restarts "Dock";

	dockSwitch = { ui, key, control }: setting {
		inherit ui;
		storage = dock key;
		value = bool;
		behaviors = [ restartsDock ];
		verify = {
			inherit pane;
			operate = [ "click" control ];
			expect = shows.checkbox control;
		};
	};

	slider = size: (size - 16) / 112.0;
in
{
	size = setting {
		ui = [ "System Settings" "Desktop & Dock" "Dock" "Size" ];
		description = "Icon size in points.";
		storage = stored "float" (dock "tilesize");
		value = number { min = 16; max = 128; };
		behaviors = [ restartsDock ];
		verify = {
			inherit pane;
			expect = {
				"16" = { "Dock Size" = slider 16; };
				"48" = { "Dock Size" = slider 48; };
				"128" = { "Dock Size" = slider 128; };
			};
		};
	};

	magnification = {
		# System Settings has no switch for this since macOS 27.
		enabled = setting {
			ui = [ "System Settings" "Desktop & Dock" "Dock" "Magnification" ];
			storage = dock "magnification";
			value = bool;
			behaviors = [ restartsDock ];
			verify = {
				inherit pane;
				expect.false = { "Dock Magnification Size" = 0; };
			};
		};

		size = setting {
			ui = [ "System Settings" "Desktop & Dock" "Dock" "Magnification" "Size" ];
			description = "Magnified icon size in points.";
			storage = stored "float" (dock "largesize");
			value = number { min = 16; max = 128; };
			behaviors = [ restartsDock ];
			relations = [
				(implies (option "magnification.enabled") true "moving the slider off \"Off\" turns magnification on")
			];
			verify = {
				inherit pane;
				expect = {
					"72" = { "Dock Magnification Size" = slider 72; };
					"128" = { "Dock Magnification Size" = slider 128; };
				};
			};
		};
	};

	dockPositionOnScreen = setting {
		ui = [ "System Settings" "Desktop & Dock" "Dock" "Dock position on screen" ];
		storage = dock "orientation";
		value = enum { Left = "left"; Bottom = "bottom"; Right = "right"; };
		behaviors = [ restartsDock ];
		verify = {
			inherit pane;
			expect = shows.choice "position" [ "Left" "Right" "Bottom" ];
		};
	};

	minimizedWindowAnimation = setting {
		ui = [ "System Settings" "Desktop & Dock" "Dock" "Minimized window animation" ];
		storage = dock "mineffect";
		value = enum { "Genie Effect" = "genie"; "Scale Effect" = "scale"; };
		behaviors = [ restartsDock ];
		verify = {
			inherit pane;
			expect = shows.choice "minimize-windows" [ "Scale Effect" "Genie Effect" ];
		};
	};

	windowTitleBarDoubleClickAction = setting {
		ui = [ "System Settings" "Desktop & Dock" "Dock" "Window title bar double-click action" ];
		storage = global "AppleActionOnDoubleClick";
		value = enum { Fill = "Fill"; Zoom = "Maximize"; Minimize = "Minimize"; "No Action" = "None"; };
		verify = {
			inherit pane;
			expect = shows.choice "double-click" [ "Zoom" "Minimize" "No Action" "Fill" ];
		};
	};

	minimizeWindowsIntoApplicationIcon = dockSwitch {
		ui = [ "System Settings" "Desktop & Dock" "Dock" "Minimize windows into application icon" ];
		key = "minimize-to-application";
		control = "minimize-into-app";
	};

	automaticallyHideAndShowTheDock = {
		enabled = dockSwitch {
			ui = [ "System Settings" "Desktop & Dock" "Dock" "Automatically hide and show the Dock" ];
			key = "autohide";
			control = "auto-hide-dock";
		};

		delay = setting {
			ui = [ "System Settings" "Desktop & Dock" "Dock" "Automatically hide and show the Dock" "Delay" ];
			description = "Seconds before a hidden Dock appears when the pointer reaches it.";
			storage = stored "float" (dock "autohide-delay");
			value = number { min = 0.0; max = 10.0; };
			behaviors = [ restartsDock ];
		};

		duration = setting {
			ui = [ "System Settings" "Desktop & Dock" "Dock" "Automatically hide and show the Dock" "Animation duration" ];
			description = "How long the Dock takes to slide in and out, in seconds; 0 turns the animation off.";
			storage = stored "float" (dock "autohide-time-modifier");
			value = number { min = 0.0; max = 10.0; };
			behaviors = [ restartsDock ];
		};
	};

	animateOpeningApplications = dockSwitch {
		ui = [ "System Settings" "Desktop & Dock" "Dock" "Animate opening applications" ];
		key = "launchanim";
		control = "animate-app-opening";
	};

	showIndicatorsForOpenApplications = dockSwitch {
		ui = [ "System Settings" "Desktop & Dock" "Dock" "Show indicators for open applications" ];
		key = "show-process-indicators";
		control = "show-indicators";
	};

	showSuggestedAndRecentAppsInDock = dockSwitch {
		ui = [ "System Settings" "Desktop & Dock" "Dock" "Show suggested and recent apps in Dock" ];
		key = "show-recents";
		control = "show-recents";
	};

	contents = setting {
		ui = [ "Dock" ];
		description = ''
			The apps on the left of the Dock's separator and the folders and stacks on the right, as
			arranged in the Dock. Save them into your configuration with
			`nix run github:sushydev/nix-plist-manager#capture -- applications.systemSettings.desktopAndDock.dock.contents <directory>`
			and set this option to that directory. Apps that aren't installed show as question marks.
		'';
		storage = {
			apps = dock "persistent-apps";
			others = dock "persistent-others";
		};
		value = snapshot;
		# The Dock saves its contents when it quits, which would overwrite what was just restored.
		behaviors = [ (restartsDiscardingItsState "Dock") ];
	};
}
