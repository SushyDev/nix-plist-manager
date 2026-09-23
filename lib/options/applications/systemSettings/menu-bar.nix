{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting global user domain byHost bool enum storedAs snapshot restarts onlyWhen;

	pane = "com.apple.settings.controlCenter";
	option = name: "applications.systemSettings.menuBar.${name}";

	clock = name: user "com.apple.menuextra.clock" name;
	groupContainer = group: "~/Library/Group Containers/${group}/Library/Preferences/${group}";

	# the menu bar clock is drawn by Control Center, which reads these at launch
	clockSwitch = { ui, key, control, relations ? [] }: setting {
		inherit relations;
		ui = [ "System Settings" "Menu Bar" "Clock Options…" ui ];
		storage = clock key;
		value = bool;
		behaviors = [ (restarts "ControlCenter") ];
		verify = {
			inherit pane;
			open = [ "Clock Options…" ];
			operate = [ "click" control ];
			expect = {
				true = { ${control} = 1; };
				false = { ${control} = 0; };
			};
		};
	};

	digitalOnly = onlyWhen (option "clock.style") (style: style == "Digital") "an analog clock doesn't show it";
in
{
	autoHideAndShowTheMenuBar = setting {
		ui = [ "System Settings" "Menu Bar" "Automatically hide and show the menu bar" ];
		storage = {
			hidden = global "_HIHideMenuBar";
			visibleInFullScreen = global "AppleMenuBarVisibleInFullscreen";
			choice = user "com.apple.controlcenter" "AutoHideMenuBarOption";
		};
		value = enum {
			Always = { hidden = true; visibleInFullScreen = false; choice = 0; };
			"On Desktop Only" = { hidden = true; visibleInFullScreen = true; choice = 1; };
			"In Full Screen Only" = { hidden = false; visibleInFullScreen = false; choice = 2; };
			Never = { hidden = false; visibleInFullScreen = true; choice = 3; };
		};
		verify = {
			inherit pane;
			expect = {
				Always = { autohide-menubar = "Always"; };
				"On Desktop Only" = { autohide-menubar = "On Desktop Only"; };
				"In Full Screen Only" = { autohide-menubar = "In Full Screen Only"; };
				Never = { autohide-menubar = "Never"; };
			};
		};
	};

	showMenuBarBackground = setting {
		ui = [ "System Settings" "Menu Bar" "Show menu bar background" ];
		storage = global "SLSMenuBarUseBlurredAppearance";
		value = bool;
		verify = {
			inherit pane;
			# the switch sits under the window's title bar, where a click doesn't reach it
			operate = [ "press" "Show menu bar background" ];
			expect = {
				true = { "Show menu bar background" = 1; };
				false = { "Show menu bar background" = 0; };
			};
		};
	};

	clock = {
		showDate = setting {
			ui = [ "System Settings" "Menu Bar" "Clock Options…" "Show date" ];
			storage = clock "ShowDate";
			value = storedAs { true = 1; false = 2; } bool;
			behaviors = [ (restarts "ControlCenter") ];
			verify = {
				inherit pane;
				open = [ "Clock Options…" ];
				operate = [ "click" "show-date" ];
				expect = {
					true = { show-date = 1; };
					false = { show-date = 0; };
				};
			};
		};

		showTheDayOfTheWeek = clockSwitch {
			ui = "Show the day of the week";
			key = "ShowDayOfWeek";
			control = "show-day-of-week";
		};

		style = setting {
			ui = [ "System Settings" "Menu Bar" "Clock Options…" "Style" ];
			storage = clock "IsAnalog";
			value = enum { Digital = false; Analog = true; };
			behaviors = [ (restarts "ControlCenter") ];
			verify = {
				inherit pane;
				open = [ "Clock Options…" ];
				operate = [ [ "press" "AXRadioButton:Analog" ] [ "press" "AXRadioButton:Digital" ] ];
				expect = {
					Digital = { "AXRadioButton:Digital" = 1; };
					Analog = { "AXRadioButton:Analog" = 1; };
				};
			};
		};

		flashTheTimeSeparators = clockSwitch {
			ui = "Flash the time separators";
			key = "FlashDateSeparators";
			control = "flash-separators";
			relations = [ digitalOnly ];
		};

		displayTheTimeWithSeconds = clockSwitch {
			ui = "Display the time with seconds";
			key = "ShowSeconds";
			control = "show-seconds";
			relations = [ digitalOnly ];
		};
	};

	# Which modules show in the menu bar and Control Center, how, and in what order, plus
	# the Battery options: arranged in System Settings and captured, rather than typed.
	layout = setting {
		ui = [ "Menu Bar" "Menu Bar Controls" ];
		description = ''
			The menu bar and Control Center layout, as arranged in System Settings. Arrange it,
			then save it into your configuration with
			`nix run github:sushydev/nix-plist-manager#capture -- applications.systemSettings.menuBar.layout <directory>`
			and set this option to that directory.
		'';
		storage = {
			modules = byHost (domain "com.apple.controlcenter");
			controlCenter = byHost (domain "com.apple.controlcenter.bentoboxes");
			menuExtras = byHost (domain "com.apple.controlcenter.displayablemenuextras");
			positions = user (groupContainer "com.apple.MenuBar") "TrailingItemPreferredPositions";
			siri = user "com.apple.Siri" "StatusMenuVisible";
			showSiri = user (groupContainer "group.com.apple.controlcenter") "showSiri";
			showSpotlight = user (groupContainer "group.com.apple.controlcenter") "showSpotlight";
		};
		value = snapshot;
		behaviors = [ (restarts "ControlCenter") ];
	};
}
