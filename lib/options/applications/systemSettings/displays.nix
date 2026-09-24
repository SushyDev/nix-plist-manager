{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user byHost mkKey bool inverted enum number appliesThrough onlyWhen live shows;

	pane = "com.apple.settings.displayAndBrightness";
	option = name: "applications.systemSettings.displays.${name}";

	# corebrightnessd's state is root-only on disk, so it's changed through the CoreBrightness client classes.
	coreBrightness = mkKey { domain = "/var/root/Library/Preferences/com.apple.CoreBrightness"; name = null; };
	coreBrightnessCall = class: call: live.jxa (lib.concatStrings [
		"ObjC.import('Foundation');"
		"$.NSBundle.bundleWithPath('/System/Library/PrivateFrameworks/CoreBrightness.framework').load;"
		"$.NSClassFromString('${class}').alloc.init.${call};"
	]);

	advanced = { ui, storage, control, value ? bool, relations ? [] }: setting {
		inherit storage value relations;
		ui = [ "System Settings" "Displays" "Advanced…" ] ++ ui;
		verify = {
			inherit pane;
			open = [ "Advanced…" ];
			operate = [ "click" control ];
			expect = shows.checkbox control;
		};
	};

	universalControl = name: byHost (user "com.apple.universalcontrol" name);
in
{
	trueTone = setting {
		ui = [ "System Settings" "Displays" "True Tone" ];
		storage = coreBrightness;
		value = bool;
		canUnset = false;
		behaviors = [ (appliesThrough (enabled: coreBrightnessCall "CBTrueToneClient" "setEnabled(${lib.boolToString enabled})")) ];
	};

	nightShift = {
		schedule = setting {
			ui = [ "System Settings" "Displays" "Night Shift…" "Schedule" ];
			storage = coreBrightness;
			value = enum { Off = 0; "Sunset to Sunrise" = 1; };
			canUnset = false;
			behaviors = [ (appliesThrough (mode: coreBrightnessCall "CBBlueLightClient" "setMode(${toString { Off = 0; "Sunset to Sunrise" = 1; }.${mode}})")) ];
		};

		colorTemperature = setting {
			ui = [ "System Settings" "Displays" "Night Shift…" "Color temperature" ];
			description = "From less warm (0) to more warm (1).";
			storage = coreBrightness;
			value = number { min = 0.0; max = 1.0; };
			canUnset = false;
			behaviors = [ (appliesThrough (strength: coreBrightnessCall "CBBlueLightClient" "setStrengthCommit(${toString strength}, true)")) ];
		};
	};

	whenConnectedToTv = setting {
		ui = [ "System Settings" "Displays" "When connected to TV" ];
		storage = byHost (user "com.apple.windowserver.displays" "TVConnectPolicy");
		value = enum {
			"Ask What to Show" = 0;
			"Mirror Entire Screen" = 1;
			"Choose Window or App" = 2;
			"Use as Extended Display" = 4;
		};
		verify = {
			inherit pane;
			expect = shows.choice "When connected to TV" [ "Ask What to Show" "Mirror Entire Screen" "Use as Extended Display" ];
		};
	};

	showResolutionsAsList = advanced {
		ui = [ "System Settings" "Show resolutions as list" ];
		storage = user "com.apple.Displays-Settings.extension" "showListByDefault";
		control = "ShowResolutionsAsListToggle";
	};

	universalControl = {
		allowPointerAndKeyboardToMoveBetweenNearbyDevices = advanced {
			ui = [ "System Settings" "Link to Mac or iPad" "Allow your pointer and keyboard to move between any nearby Mac or iPad" ];
			storage = universalControl "Disable";
			value = inverted bool;
			control = "UniversalControlShareKeyboardToggle";
		};

		pushThroughTheEdgeOfADisplayToConnect = advanced {
			ui = [ "System Settings" "Link to Mac or iPad" "Push through the edge of a display to connect a nearby Mac or iPad" ];
			storage = universalControl "DisableMagicEdges";
			value = inverted bool;
			control = "UniversalControlMagicEdgesToggle";
			relations = [
				(onlyWhen (option "universalControl.allowPointerAndKeyboardToMoveBetweenNearbyDevices") (allowed: allowed)
					"it's part of moving the pointer and keyboard between devices")
			];
		};
	};
}
