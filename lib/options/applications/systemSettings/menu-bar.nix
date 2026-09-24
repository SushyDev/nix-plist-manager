{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting global user byHost bool enum inDict member storedAs snapshot restarts onlyWhen appliesThrough live;

	pane = "com.apple.settings.controlCenter";
	option = name: "applications.systemSettings.menuBar.${name}";

	clock = name: user "com.apple.menuextra.clock" name;
	groupContainer = group: "~/Library/Group Containers/${group}/Library/Preferences/${group}";

	clockSwitch = { ui, key, control, relations ? [] }: setting {
		inherit relations;
		ui = [ "System Settings" "Menu Bar" "Clock Options…" ui ];
		storage = clock key;
		value = bool;
		behaviors = [ (restarts "ControlCenter") ];
		verify = if control == null then null else {
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

	# Control Center keeps each module's menu bar state as a bitmask: 2 shown, 8 hidden, 16 Always Show.
	controlCenter = name: byHost (user "com.apple.controlcenter" name);

	checkbox = id: "AXCheckBox:controlcenter-${id}-id";
	popup = id: "AXPopUpButton:controlcenter-${id}-id";

	moduleWithMenu = { ui, key, id }: setting {
		ui = [ "System Settings" "Menu Bar" "Menu Bar Controls" ui ];
		storage = controlCenter key;
		value = enum { "Don't Show" = 24; "Show When Active" = 2; "Always Show" = 18; };
		behaviors = [ (restarts "ControlCenter") ];
		verify = {
			inherit pane;
			expect = {
				"Don't Show" = { ${checkbox id} = 0; };
				"Show When Active" = { ${checkbox id} = 1; ${popup id} = "Show When Active"; };
				"Always Show" = { ${checkbox id} = 1; ${popup id} = "Always Show"; };
			};
		};
	};

	module = { ui, key, id, shown, hidden }: setting {
		ui = [ "System Settings" "Menu Bar" "Menu Bar Controls" ui ];
		storage = controlCenter key;
		value = storedAs { true = shown; false = hidden; } bool;
		behaviors = [ (restarts "ControlCenter") ];
		verify = {
			inherit pane;
			expect = {
				true = { ${checkbox id} = 1; };
				false = { ${checkbox id} = 0; };
			};
		};
	};
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
			# The switch sits under the window's title bar, where a click doesn't reach it.
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

		showAmPm = clockSwitch {
			ui = "Show AM/PM";
			key = "ShowAMPM";
			control = null;
		};

		announceTheTime = let
			timeAnnouncements = user "com.apple.speech.synthesis.general.prefs" "TimeAnnouncementPrefs";
			entry = ui: control: value: setting {
				inherit value;
				ui = [ "System Settings" "Menu Bar" "Clock Options…" ui ];
				storage = timeAnnouncements;
				canUnset = false;
				verify = {
					inherit pane;
					open = [ "Clock Options…" ];
					expect = lib.mapAttrs (_: shown: { ${control} = shown; })
						(if value.kind == "bool" then { true = 1; false = 0; } else { "On the hour" = "On the hour"; "On the quarter hour" = "On the quarter hour"; });
				};
			};
		in {
			enable = entry "Announce the time" "announce-time" (inDict "TimeAnnouncementsEnabled" bool);

			interval = entry "Interval" "time-interval" (inDict "TimeAnnouncementsIntervalIdentifier" (enum {
				"On the hour" = "EveryHourInterval";
				"On the half hour" = "EveryHalfHourInterval";
				"On the quarter hour" = "EveryQuarterHourInterval";
			}));
		};
	};

	wifi = module { ui = "Wi‑Fi"; key = "WiFi"; id = "wifi"; shown = 18; hidden = 24; };
	bluetooth = module { ui = "Bluetooth"; key = "Bluetooth"; id = "bluetooth"; shown = 18; hidden = 24; };
	airdrop = module { ui = "AirDrop"; key = "AirDrop"; id = "airdrop"; shown = 18; hidden = 24; };
	battery = module { ui = "Battery"; key = "Battery"; id = "battery"; shown = 2; hidden = 8; };
	timeMachine = setting {
		ui = [ "System Settings" "Menu Bar" "Menu Bar Controls" "Time Machine" ];
		storage = user "com.apple.systemuiserver" "menuExtras";
		value = member { item = "/System/Library/CoreServices/Menu Extras/TimeMachine.menu"; };
		behaviors = [ (restarts "SystemUIServer") ];
		verify = {
			inherit pane;
			settle = 5;
			expect = {
				true = { ${checkbox "timeMachine"} = 1; };
				false = { ${checkbox "timeMachine"} = 0; };
			};
		};
	};
	keyboardBrightness = module { ui = "Keyboard Brightness"; key = "KeyboardBrightness"; id = "keyboardBrightness"; shown = 2; hidden = 8; };

	focusModes = moduleWithMenu { ui = "Focus"; key = "FocusModes"; id = "focus"; };
	screenMirroring = moduleWithMenu { ui = "Screen Mirroring"; key = "ScreenMirroring"; id = "screenMirroring"; };
	display = moduleWithMenu { ui = "Display"; key = "Display"; id = "display"; };
	sound = moduleWithMenu { ui = "Sound"; key = "Sound"; id = "sound"; };
	nowPlaying = moduleWithMenu { ui = "Now Playing"; key = "NowPlaying"; id = "nowPlaying"; };
	timer = moduleWithMenu { ui = "Timer"; key = "Timer"; id = "timer"; };

	siri = setting {
		ui = [ "System Settings" "Menu Bar" "Menu Bar Controls" "Siri" ];
		storage = {
			module = controlCenter "Siri";
			statusMenu = user "com.apple.Siri" "StatusMenuVisible";
		};
		value = storedAs {
			true = { module = 2; statusMenu = true; };
			false = { module = 8; statusMenu = false; };
		} bool;
		behaviors = [ (restarts "ControlCenter") ];
		verify = {
			inherit pane;
			expect = {
				true = { ${checkbox "siri"} = 1; };
				false = { ${checkbox "siri"} = 0; };
			};
		};
	};

	textInput = setting {
		ui = [ "System Settings" "Menu Bar" "Menu Bar Controls" "Text Input" ];
		storage = user "com.apple.TextInputMenu" "visible";
		value = bool;
		behaviors = [ (restarts "TextInputMenuAgent") ];
		verify = {
			inherit pane;
			expect = {
				true = { ${checkbox "textInput"} = 1; };
				false = { ${checkbox "textInput"} = 0; };
			};
		};
	};

	fastUserSwitching = module { ui = "Fast User Switching"; key = "UserSwitcher"; id = "userSwitcher"; shown = 3; hidden = 9; };

	fastUserSwitchingShowAs = setting {
		ui = [ "System Settings" "Menu Bar" "Menu Bar Controls" "Fast User Switching" "Show in Menu Bar" ];
		storage = global "userMenuExtraStyle";
		value = enum { "Full Name" = 0; "Account Name" = 1; Icon = 2; };
		behaviors = [ (restarts "ControlCenter") ];
		relations = [
			(onlyWhen (option "fastUserSwitching") (shown: shown) "it's how Fast User Switching shows in the menu bar")
		];
	};

	batteryOptions = {
		showPercentage = setting {
			ui = [ "System Settings" "Menu Bar" "Menu Bar Controls" "Battery Options…" "Show Percentage" ];
			storage = controlCenter "BatteryShowPercentage";
			value = bool;
			behaviors = [ (restarts "ControlCenter") ];
			verify = {
				inherit pane;
				open = [ "Battery Options…" ];
				expect = {
					true = { show-battery-percentage-switch = 1; };
					false = { show-battery-percentage-switch = 0; };
				};
			};
		};

		showEnergyMode = setting {
			ui = [ "System Settings" "Menu Bar" "Menu Bar Controls" "Battery Options…" "Show Energy Mode" ];
			storage = controlCenter "BatteryShowEnergyMode";
			value = enum { "When Active" = 0; Always = 1; };
			behaviors = [ (restarts "ControlCenter") ];
			verify = {
				inherit pane;
				open = [ "Battery Options…" ];
				expect = {
					"When Active" = { "Show Energy Mode" = "When Active"; };
					Always = { "Show Energy Mode" = "Always"; };
				};
			};
		};
	};

	showSuggestionsInControlGallery = setting {
		ui = [ "System Settings" "Menu Bar" "Show suggestions in Control Gallery" ];
		storage = controlCenter "ShowSuggestions";
		value = bool;
		behaviors = [ (restarts "ControlCenter") ];
		verify = {
			inherit pane;
			operate = [ "click" "Show suggestions in Control Gallery" ];
			expect = {
				true = { "Show suggestions in Control Gallery" = 1; };
				false = { "Show suggestions in Control Gallery" = 0; };
			};
		};
	};

	recentDocumentsApplicationsAndServers = let
		amounts = { None = 0; "5" = 5; "10" = 10; "15" = 15; "20" = 20; "30" = 30; "50" = 50; };
	in setting {
		ui = [ "System Settings" "Menu Bar" "Recent documents, applications, and servers" ];
		# NumberOfRecents only mirrors the limit, which the shared file lists keep.
		storage = user "com.apple.controlcenter" "NumberOfRecents";
		value = enum amounts;
		behaviors = [
			(appliesThrough (label: [
				(live.recentItems amounts.${label})
				"/usr/bin/defaults write com.apple.controlcenter NumberOfRecents -int ${toString amounts.${label}}"
			]))
		];
		verify = {
			inherit pane;
			expect = {
				None = { recents = "None"; };
				"5" = { recents = "5"; };
				"10" = { recents = "10"; };
			};
		};
	};

	layout = setting {
		ui = [ "Menu bar" ];
		description = ''
			Which apps' items show in the menu bar (verified), the order of menu bar items and whether
			Siri and Spotlight show (not verified yet), as arranged by hand. Save them into your
			configuration with
			`nix run github:sushydev/nix-plist-manager#capture -- applications.systemSettings.menuBar.layout <directory>`
			and set this option to that directory. Control Center's own contents can't be declared.
		'';
		storage = {
			applications = user (groupContainer "group.com.apple.controlcenter") "trackedApplications";
			positions = user (groupContainer "com.apple.MenuBar") "TrailingItemPreferredPositions";
			showSiri = user (groupContainer "group.com.apple.controlcenter") "showSiri";
			showSpotlight = user (groupContainer "group.com.apple.controlcenter") "showSpotlight";
		};
		value = snapshot;
		behaviors = [ (restarts "ControlCenter") ];
	};
}
