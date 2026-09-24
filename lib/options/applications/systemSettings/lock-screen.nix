{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting system bool inverted storedAs text enum appliesThrough live shows;

	pane = "com.apple.settings.lockScreen";
	loginWindow = system "com.apple.loginwindow";

	displayTimes = {
		"For 1 minute" = 1; "For 2 minutes" = 2; "For 3 minutes" = 3; "For 5 minutes" = 5;
		"For 10 minutes" = 10; "For 20 minutes" = 20; "For 30 minutes" = 30; "For 1 hour" = 60;
		"For 1 hour, 30 minutes" = 90; "For 2 hours" = 120; "For 2 hours, 30 minutes" = 150;
		"For 3 hours" = 180; Never = 0;
	};

	turnDisplayOff = { ui, source, dictionary }: setting {
		ui = [ "System Settings" "Lock Screen" ui ];
		storage = system "com.apple.PowerManagement" dictionary;
		value = enum displayTimes;
		canUnset = false;
		behaviors = [ (appliesThrough (time: "/usr/bin/pmset -${source} displaysleep ${toString displayTimes.${time}}")) ];
		reads = { command = live.pmsetValue dictionary "displaysleep"; values = displayTimes; };
		verify = {
			inherit pane;
			expect = shows.choice "AXPopUpButton:${ui}" [ "For 10 minutes" "Never" ];
		};
	};

	switch = { ui, storage, value ? bool }: setting {
		inherit storage value;
		ui = [ "System Settings" "Lock Screen" ui ];
		verify = {
			inherit pane;
			expect = shows.checkbox "AXCheckBox:${ui}";
		};
	};
in
{
	turnDisplayOffOnBatteryWhenInactive = turnDisplayOff {
		ui = "Turn display off on battery when inactive";
		source = "b";
		dictionary = "Battery Power";
	};

	turnDisplayOffOnPowerAdapterWhenInactive = turnDisplayOff {
		ui = "Turn display off on power adapter when inactive";
		source = "c";
		dictionary = "AC Power";
	};

	showPasswordHints = switch {
		ui = "Show password hints";
		storage = loginWindow "RetriesUntilHint";
		value = storedAs { true = 3; false = 0; } bool;
	};

	messageWhenLocked = setting {
		ui = [ "System Settings" "Lock Screen" "Show message when locked" "Set…" ];
		description = "The message shown on the lock screen and login window. Unset shows none.";
		storage = loginWindow "LoginwindowText";
		value = text;
		verify = {
			inherit pane;
			expect = {
				"Back soon" = { "AXCheckBox:Show message when locked" = 1; };
			};
		};
	};

	loginWindowShows = setting {
		ui = [ "System Settings" "Lock Screen" "Login window shows" ];
		storage = loginWindow "SHOWFULLNAME";
		value = enum { "List of users" = false; "Name and password" = true; };
		verify = {
			inherit pane;
			expect = shows.radio [ "List of users" "Name and password" ];
		};
	};

	showTheSleepRestartAndShutDownButtons = switch {
		ui = "Show the Sleep, Restart, and Shut Down buttons";
		storage = loginWindow "PowerOffDisabled";
		value = inverted bool;
	};
}
