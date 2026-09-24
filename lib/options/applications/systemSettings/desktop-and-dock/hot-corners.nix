{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user enum flags restarts family onlyWhen;

	pane = "com.apple.settings.desktopAndDock";
in
family {
	topLeft = { corner = "tl"; label = "Top Left"; };
	topRight = { corner = "tr"; label = "Top Right"; };
	bottomLeft = { corner = "bl"; label = "Bottom Left"; };
	bottomRight = { corner = "br"; label = "Bottom Right"; };
} ({ name, corner, label }: {
	action = setting {
		ui = [ "System Settings" "Desktop & Dock" "Hot Corners…" "${label} Hot Corner" ];
		storage = user "com.apple.dock" "wvous-${corner}-corner";
		value = enum {
			"-" = 1;
			"Mission Control" = 2;
			"Application Windows" = 3;
			"Desktop" = 4;
			"Start Screen Saver" = 5;
			"Disable Screen Saver" = 6;
			"Put Display to Sleep" = 10;
			"Apps" = 11;
			"Notification Center" = 12;
			"Lock Screen" = 13;
			"Quick Note" = 14;
		};
		behaviors = [ (restarts "Dock") ];
		verify = {
			inherit pane;
			open = [ "Hot Corners…" ];
			expect = {
				"-" = { "${label} Hot Corner" = "-"; };
				"Mission Control" = { "${label} Hot Corner" = "Mission Control"; };
				"Quick Note" = { "${label} Hot Corner" = "Quick Note"; };
			};
		};
	};

	# keys to hold for the corner to trigger, picked in System Settings by holding them while
	# opening the menu
	modifiers = setting {
		ui = [ "System Settings" "Desktop & Dock" "Hot Corners…" "${label} Hot Corner" "Modifier keys" ];
		storage = user "com.apple.dock" "wvous-${corner}-modifier";
		value = flags { shift = 131072; control = 262144; option = 524288; command = 1048576; };
		behaviors = [ (restarts "Dock") ];
		relations = [
			(onlyWhen "applications.systemSettings.desktopAndDock.hotCorners.${name}.action" (action: action != "-")
				"a corner without an action doesn't use modifier keys")
		];
	};
})
