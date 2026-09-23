{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user global bool inverted restarts;

	pane = "com.apple.settings.desktopAndDock";

	switch = { ui, storage, control, value ? bool, behaviors ? [], description ? "" }: setting {
		inherit ui storage value behaviors description;
		verify = {
			inherit pane;
			operate = [ "click" control ];
			expect = {
				true = { ${control} = 1; };
				false = { ${control} = 0; };
			};
		};
	};

	# Mission Control is part of the Dock, which reads these at launch
	dockSwitch = { ui, key, control }: switch {
		inherit ui control;
		storage = user "com.apple.dock" key;
		behaviors = [ (restarts "Dock") ];
	};
in
{
	automaticallyRearrangeSpacesBasedOnMostRecentUse = dockSwitch {
		ui = [ "System Settings" "Desktop & Dock" "Mission Control" "Automatically rearrange Spaces based on most recent use" ];
		key = "mru-spaces";
		control = "auto-reorder-spaces";
	};

	whenSwitchingToAnApplicationSwitchToAspaceWithOpenWindowsForTheApplication = switch {
		ui = [ "System Settings" "Desktop & Dock" "Mission Control" "When switching to an application, switch to a Space with open windows for the application" ];
		storage = global "AppleSpacesSwitchOnActivate";
		control = "switch-space-on-active";
	};

	groupWindowsByApplication = dockSwitch {
		ui = [ "System Settings" "Desktop & Dock" "Mission Control" "Group windows by application" ];
		key = "expose-group-apps";
		control = "group-windows-by-application";
	};

	displaysHaveSeparateSpaces = switch {
		ui = [ "System Settings" "Desktop & Dock" "Mission Control" "Displays have separate Spaces" ];
		description = "Takes effect after logging out.";
		storage = user "com.apple.spaces" "spans-displays";
		value = inverted bool;
		control = "displays-have-separate-spaces";
	};

	dragWindowsToTopOfScreenToEnterMissionControl = dockSwitch {
		ui = [ "System Settings" "Desktop & Dock" "Mission Control" "Drag windows to top of screen to enter Mission Control" ];
		key = "enterMissionControlByTopWindowDrag";
		control = "enter-mission-control-by-top-window-drag";
	};
}
