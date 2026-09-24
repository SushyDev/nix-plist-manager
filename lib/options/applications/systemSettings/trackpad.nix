{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting global user byHost bool enum number storedAs restarts allowedWhen conflictsWith shows;

	pane = "com.apple.settings.trackpad";
	option = name: "applications.systemSettings.trackpad.${name}";

	gesture = name: hostName: {
		driver = user "com.apple.AppleMultitouchTrackpad" name;
		bluetooth = user "com.apple.driver.AppleBluetoothMultitouch.trackpad" name;
		host = byHost (global "com.apple.trackpad.${hostName}");
	};
	everywhere = value: { driver = value; bluetooth = value; host = value; };
	dock = name: user "com.apple.dock" name;

	control = { tab, ui, storage, value, verify ? {}, behaviors ? [], relations ? [] }: setting {
		inherit storage value behaviors relations;
		ui = [ "System Settings" "Trackpad" tab ui ];
		verify = if verify == {} then null else {
			inherit pane;
			open = [ "AXRadioButton:${tab}" ];
		} // verify;
	};

	switch = { tab, ui, storage, value ? bool, behaviors ? [] }: control {
		inherit tab ui storage value behaviors;
		verify.expect = shows.checkbox "AXCheckBox:${ui}";
	};

	gestureSwitch = { tab, ui, name, hostName, on ? true, off ? false }: switch {
		inherit tab ui;
		storage = gesture name hostName;
		value = storedAs { true = everywhere on; false = everywhere off; } bool;
	};

	picks = ui: labels: lib.genAttrs labels (label: { "AXPopUpButton:${ui}" = label; });

	threeFingerHorizontal = gesture "TrackpadThreeFingerHorizSwipeGesture" "threeFingerHorizSwipeGesture";
	fourFingerHorizontal = gesture "TrackpadFourFingerHorizSwipeGesture" "fourFingerHorizSwipeGesture";
	threeFingerVertical = gesture "TrackpadThreeFingerVertSwipeGesture" "threeFingerVertSwipeGesture";
	fourFingerVertical = gesture "TrackpadFourFingerVertSwipeGesture" "fourFingerVertSwipeGesture";
	threeFingerTap = gesture "TrackpadThreeFingerTapGesture" "threeFingerTapGesture";

	prefixed = prefix: attrs: lib.mapAttrs' (name: lib.nameValuePair "${prefix}${name}") attrs;

	verticalSwipe = { ui, direction, enabled, other }: control {
		tab = "More Gestures";
		inherit ui;
		storage = { inherit enabled; } // prefixed "three" threeFingerVertical // prefixed "four" fourFingerVertical;
		value = enum {
			Off = { enabled = false; };
			"Swipe ${direction} with Three Fingers" = { enabled = true; } // prefixed "three" (everywhere 2) // prefixed "four" (everywhere 0);
			"Swipe ${direction} with Four Fingers" = { enabled = true; } // prefixed "three" (everywhere 0) // prefixed "four" (everywhere 2);
		};
		behaviors = [ (restarts "Dock") ];
		relations = [
			(context: lib.optionals (context.value != "Off")
				(conflictsWith (option "moreGestures.${other}")
					(value: value != "Off" && lib.hasInfix "Four" value != lib.hasInfix "Four" context.value)
					"Mission Control and App Exposé swipe with the same number of fingers" context))
		];
		verify.expect = picks ui [ "Off" "Swipe ${direction} with Three Fingers" "Swipe ${direction} with Four Fingers" ];
	};
in
{
	pointAndClick = {
		trackingSpeed = control {
			tab = "Point & Click";
			ui = "Tracking speed";
			storage = global "com.apple.trackpad.scaling";
			value = number { min = 0.0; max = 3.0; };
		};

		click = control {
			tab = "Point & Click";
			ui = "Click";
			storage = {
				first = user "com.apple.AppleMultitouchTrackpad" "FirstClickThreshold";
				second = user "com.apple.AppleMultitouchTrackpad" "SecondClickThreshold";
			};
			value = enum (lib.mapAttrs (_: level: { first = level; second = level; }) { Light = 0; Medium = 1; Firm = 2; });
			verify.expect = { Light = { "AXSlider:ClickPressureSlider" = 0; }; Firm = { "AXSlider:ClickPressureSlider" = 2; }; };
		};

		forceClickAndHapticFeedback = switch {
			tab = "Point & Click";
			ui = "Force Click and haptic feedback";
			storage = {
				detents = user "com.apple.AppleMultitouchTrackpad" "ActuateDetents";
				suppressed = user "com.apple.AppleMultitouchTrackpad" "ForceSuppressed";
			};
			value = storedAs {
				true = { detents = 1; suppressed = false; };
				false = { detents = 0; suppressed = true; };
			} bool;
		};

		lookUpAndDataDetectors = control {
			tab = "Point & Click";
			ui = "Look up & data detectors";
			storage = { forceClick = global "com.apple.trackpad.forceClick"; } // threeFingerTap;
			value = enum {
				Off = { forceClick = false; } // everywhere 0;
				"Force Click with One Finger" = { forceClick = true; } // everywhere 0;
				"Tap with Three Fingers" = { forceClick = false; } // everywhere 2;
			};
			relations = [
				(allowedWhen "Force Click with One Finger" (option "pointAndClick.forceClickAndHapticFeedback") (enabled: enabled)
					"Force Click needs Force Click and haptic feedback")
			];
			verify.expect = picks "Look up & data detectors" [ "Off" "Tap with Three Fingers" "Force Click with One Finger" ];
		};

		secondaryClick = control {
			tab = "Point & Click";
			ui = "Secondary click";
			storage = {
				twoFingers = user "com.apple.AppleMultitouchTrackpad" "TrackpadRightClick";
				twoFingersBluetooth = user "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadRightClick";
				twoFingersHost = byHost (global "com.apple.trackpad.enableSecondaryClick");
				corner = user "com.apple.AppleMultitouchTrackpad" "TrackpadCornerSecondaryClick";
				cornerBluetooth = user "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadCornerSecondaryClick";
				cornerHost = byHost (global "com.apple.trackpad.trackpadCornerClickBehavior");
				contextMenu = global "ContextMenuGesture";
			};
			value = let
				twoFingers = on: { twoFingers = on; twoFingersBluetooth = on; twoFingersHost = on; };
				corner = device: host: { corner = device; cornerBluetooth = device; cornerHost = host; };
			in enum {
				Off = twoFingers false // corner 0 0 // { contextMenu = 0; };
				"Click or Tap with Two Fingers" = twoFingers true // corner 0 0 // { contextMenu = 1; };
				"Click in Bottom Right Corner" = twoFingers false // corner 2 1 // { contextMenu = 1; };
				"Click in Bottom Left Corner" = twoFingers false // corner 1 3 // { contextMenu = 1; };
			};
			verify.expect = picks "Secondary click" [ "Off" "Click in Bottom Right Corner" "Click or Tap with Two Fingers" ];
		};

		tapToClick = switch {
			tab = "Point & Click";
			ui = "Tap to click";
			storage = {
				driver = user "com.apple.AppleMultitouchTrackpad" "Clicking";
				bluetooth = user "com.apple.driver.AppleBluetoothMultitouch.trackpad" "Clicking";
				host = byHost (global "com.apple.mouse.tapBehavior");
			};
			value = storedAs {
				true = { driver = true; bluetooth = true; host = 1; };
				false = { driver = false; bluetooth = false; host = 0; };
			} bool;
		};
	};

	scrollAndZoom = {
		naturalScrolling = switch {
			tab = "Scroll & Zoom";
			ui = "Natural scrolling";
			storage = global "com.apple.swipescrolldirection";
		};

		zoomInOrOut = gestureSwitch {
			tab = "Scroll & Zoom";
			ui = "Zoom in or out";
			name = "TrackpadPinch";
			hostName = "pinchGesture";
		};

		smartZoom = gestureSwitch {
			tab = "Scroll & Zoom";
			ui = "Smart zoom";
			name = "TrackpadTwoFingerDoubleTapGesture";
			hostName = "twoFingerDoubleTapGesture";
			on = 1;
			off = 0;
		};

		rotate = gestureSwitch {
			tab = "Scroll & Zoom";
			ui = "Rotate";
			name = "TrackpadRotate";
			hostName = "rotateGesture";
		};
	};

	# Full-screen applications is applied first, so a three-finger page swipe wins where both are set.
	moreGestures = {
		swipeBetweenFullScreenApplications = control {
			tab = "More Gestures";
			ui = "Swipe between full-screen applications";
			storage = prefixed "three" threeFingerHorizontal // prefixed "four" fourFingerHorizontal;
			value = enum {
				Off = prefixed "three" (everywhere 0) // prefixed "four" (everywhere 0);
				"Swipe Left or Right with Three Fingers" = prefixed "three" (everywhere 2) // prefixed "four" (everywhere 0);
				"Swipe Left or Right with Four Fingers" = prefixed "three" (everywhere 0) // prefixed "four" (everywhere 2);
			};
			verify.expect = picks "Swipe between full-screen applications" [ "Off" "Swipe Left or Right with Four Fingers" "Swipe Left or Right with Three Fingers" ];
		};

		swipeBetweenPages = control {
			tab = "More Gestures";
			ui = "Swipe between pages";
			storage = { scrolls = global "AppleEnableSwipeNavigateWithScrolls"; } // threeFingerHorizontal;
			value = enum {
				Off = { scrolls = false; };
				"Scroll Left or Right with Two Fingers" = { scrolls = true; };
				"Swipe with Three Fingers" = { scrolls = false; } // everywhere 1;
				"Swipe with Two or Three Fingers" = { scrolls = true; } // everywhere 1;
			};
			relations = [
				(context: lib.optionals (lib.hasInfix "Three" context.value)
					(conflictsWith (option "moreGestures.swipeBetweenFullScreenApplications")
						(fullScreen: fullScreen == "Swipe Left or Right with Three Fingers")
						"both would use the three-finger swipe" context))
			];
			verify.expect = picks "Swipe between pages" [ "Off" "Swipe with Two or Three Fingers" "Scroll Left or Right with Two Fingers" ];
		};

		notificationCenter = gestureSwitch {
			tab = "More Gestures";
			ui = "Notification Center";
			name = "TrackpadTwoFingerFromRightEdgeSwipeGesture";
			hostName = "twoFingerFromRightEdgeSwipeGesture";
			on = 3;
			off = 0;
		};

		missionControl = verticalSwipe {
			ui = "Mission Control";
			direction = "Up";
			enabled = dock "showMissionControlGestureEnabled";
			other = "appExpose";
		};

		appExpose = verticalSwipe {
			ui = "App Exposé";
			direction = "Down";
			enabled = dock "showAppExposeGestureEnabled";
			other = "missionControl";
		};

		showDesktop = switch {
			tab = "More Gestures";
			ui = "Show Desktop";
			storage = dock "showDesktopGestureEnabled";
			behaviors = [ (restarts "Dock") ];
		};
	};
}
