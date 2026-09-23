{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user global bool enum inverted restarts activatesShortcuts ops;

	pane = "com.apple.settings.desktopAndDock";

	# Keyboard & Mouse Shortcuts…: each shortcut is a key (with modifiers) or a modifier key on
	# its own, kept as entries of com.apple.symbolichotkeys AppleSymbolicHotKeys. Each has a
	# second entry for the same shortcut with Shift, which System Settings writes too.
	hotKeys = user "com.apple.symbolichotkeys" "AppleSymbolicHotKeys";

	shift = 131072;
	modifierMasks = { "⌃" = 262144; "⌥" = 524288; "⇧" = shift; "⌘" = 1048576; };
	# arrow keys carry the function-key flag
	functionKey = 8388608;
	keyCodes = {
		F1 = 122; F2 = 120; F3 = 99; F4 = 118; F5 = 96; F6 = 97; F7 = 98; F8 = 100; F9 = 101;
		F10 = 109; F11 = 103; F12 = 111; F13 = 105;
		"←" = 123; "→" = 124; "↓" = 125; "↑" = 126;
	};
	arrows = [ "←" "→" "↓" "↑" ];
	# a modifier key pressed on its own, by the device bit of that key
	modifierKeys = {
		"Left Control" = 1; "Left Shift" = 2; "Right Shift" = 4; "Left Command" = 8; "Right Command" = 16;
		"Left Option" = 32; "Right Option" = 64; "Right Control" = 8192; fn = functionKey;
	};

	# every combination of ⌃⌥⇧⌘, in the order System Settings shows them
	modifierCombinations = lib.foldr (glyph: rest: rest ++ map (combination: [ glyph ] ++ combination) rest) [ [] ]
		(lib.reverseList (lib.attrNames modifierMasks));
	sum = lib.foldl' builtins.bitOr 0;
	ordered = combination: lib.filter (glyph: lib.elem glyph combination) [ "⌃" "⌥" "⇧" "⌘" ];

	off = { enabled = false; };
	standard = parameters: { enabled = true; value = { type = "standard"; inherit parameters; }; };
	modifier = mask: { enabled = true; value = { type = "modifier"; parameters = [ mask mask ]; }; };

	# the dictionary entries for one choice; ids = { key; keyShifted; modifier; modifierShifted; }
	entries = ids: choice:
		let
			keyEntries = key: shifted: { ${toString ids.key} = key; ${toString ids.keyShifted} = shifted; };
			modifierEntries = plain: shifted: { ${toString ids.modifier} = plain; ${toString ids.modifierShifted} = shifted; };
		in
		if choice == "-" then keyEntries off off // modifierEntries off off
		else if modifierKeys ? ${choice} then
			keyEntries off off // modifierEntries (modifier modifierKeys.${choice}) (modifier (builtins.bitOr modifierKeys.${choice} shift))
		else if lib.hasPrefix "fn F" choice then
			let
				key = lib.removePrefix "fn " choice;
			in
			keyEntries (standard [ 65535 keyCodes.${key} functionKey ]) (standard [ 65535 keyCodes.${key} (functionKey + shift) ])
			// modifierEntries off off
		else
			let
				# the modifier glyphs in front of the key; glyphs are several bytes, so strip them as strings
				split = text:
					let
						glyph = lib.findFirst (glyph: lib.hasPrefix glyph text) null (lib.attrNames modifierMasks);
					in
					if glyph == null then { combination = []; key = text; }
					else let rest = split (lib.removePrefix glyph text); in rest // { combination = [ glyph ] ++ rest.combination; };
				inherit (split choice) combination key;
				mask = sum (map (glyph: modifierMasks.${glyph}) combination) + (if lib.elem key arrows then functionKey else 0);
			in
			keyEntries (standard [ 65535 keyCodes.${key} mask ]) (standard [ 65535 keyCodes.${key} (builtins.bitOr mask shift) ])
			// modifierEntries off off;

	functionKeys = lib.filter (key: lib.hasPrefix "F" key) (lib.attrNames keyCodes);

	# "fn F11" is an F-key with the function-key flag, as macOS sets Show Desktop by default;
	# System Settings shows it as plain "F11"
	choices = [ "-" ] ++ lib.attrNames modifierKeys ++ map (key: "fn ${key}") functionKeys
		++ lib.concatMap (key: map (combination: lib.concatStrings (ordered combination) + key) modifierCombinations)
			(lib.attrNames keyCodes);

	shortcut = { ui, ids }: setting {
		ui = [ "System Settings" "Desktop & Dock" "Mission Control" "Shortcuts…" ui ];
		description = ''
			"-" for none, a modifier key on its own ("Left Control", "fn", …), or a key with
			modifiers written as System Settings shows it: "F5", "⌃↑", "⌥⌘F1". "fn F11" is F11 with
			the function-key flag, the Show Desktop default.
		'';
		storage = hotKeys;
		value = enum (lib.genAttrs choices (choice: { value = entries ids choice; })) // {
			encode = keys: choice: [ (ops.mergeDict keys.value (entries ids choice)) ];
		};
		# unset would delete every keyboard shortcut on the Mac
		canUnset = false;
		behaviors = [ activatesShortcuts ];
		verify = {
			inherit pane;
			open = [ "Shortcuts…" ];
			# the pop-up puts a space between the modifiers and an F-key
			expect = { "⌥F1" = { "AXPopUpButton:${ui}" = "⌥ F1"; }; "⌃F2" = { "AXPopUpButton:${ui}" = "⌃ F2"; }; };
		};
	};

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

	shortcuts = {
		missionControl = shortcut {
			ui = "Mission Control";
			ids = { key = 32; keyShifted = 34; modifier = 44; modifierShifted = 46; };
		};

		# System Settings writes this one's Shift entries over Mission Control's (34 and 46); these
		# are the ones macOS itself uses for Application windows
		applicationWindows = shortcut {
			ui = "Application windows";
			ids = { key = 33; keyShifted = 35; modifier = 45; modifierShifted = 47; };
		};

		showDesktop = shortcut {
			ui = "Show Desktop";
			ids = { key = 36; keyShifted = 37; modifier = 48; modifierShifted = 49; };
		};
	};
}
