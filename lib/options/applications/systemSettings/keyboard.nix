{ lib, settingsLib, ... }:
# Keyboard brightness and backlight belong to the keyboard and change often, modifier keys are
# per keyboard, and the microphone follows what's connected, so none of them are here. The Input
# menu is in Menu Bar.
let
	inherit (settingsLib) setting global user bool storedAs enum number inDict hotKey activatesShortcuts shortcuts ops live appliesThrough strings;

	pane = "com.apple.settings.keyboard";

	switch = { ui, storage, control ? lib.last ui, value ? bool, open ? [] }: setting {
		inherit storage value;
		ui = [ "System Settings" "Keyboard" ] ++ ui;
		verify = {
			inherit pane open;
			expect = {
				true = { "AXCheckBox:${control}" = 1; };
				false = { "AXCheckBox:${control}" = 0; };
			};
		};
	};

	# Text Input > Input Sources > Edit…
	textInput = ui: storage: switch {
		inherit storage;
		ui = [ "Text Input" "Input Sources" "Edit…" ui ];
		open = [ "Edit…" ];
	};
	# Keyboard Shortcuts…: entries of com.apple.symbolichotkeys AppleSymbolicHotKeys by id, each
	# { enabled; value = { type = "standard"; parameters = [ character keyCode modifiers ]; }; }.
	# Mission Control's shortcuts are in Desktop & Dock and Zoom's in Accessibility.
	hotKeys = user "com.apple.symbolichotkeys" "AppleSymbolicHotKeys";

	# one row of Keyboard Shortcuts…. Rows inside a collapsible group (Zoom, Halves, …) take
	# `group = { name; position; switches ? true; }`: its name is part of the path, and verify
	# expands it (the position-th group of the category). In groups without `switches` only the
	# group has a checkbox.
	#
	# `testKeys` are the keys verify sets: a different combination per row, so a category's rows
	# can be checked together.
	shortcut = { category, sidebar, ui, id, testKeys, group ? null, verifiable ? true }: let
		rowSwitch = group == null || group.switches or true;
	in setting {
		ui = [ "System Settings" "Keyboard" "Keyboard Shortcuts…" category ]
			++ lib.optional (group != null) group.name ++ [ ui ];
		description = ''
			false turns the shortcut off and true on with its default keys; keys such as "⌘⇧S" (⌃⌥⇧⌘
			and one key: a letter, digit or punctuation of the US layout, Space, Return, Tab, Delete,
			Escape, an arrow, Home, End, PageUp, PageDown, ForwardDelete or F1–F20) set its keys.
		'';
		storage = hotKeys;
		value = hotKey id;
		# unset would delete every keyboard shortcut on the Mac
		canUnset = false;
		behaviors = [ activatesShortcuts ];
		verify = if !verifiable then null else {
			inherit pane;
			open = [ "AXButton:Keyboard Shortcuts…" "click:${sidebar}" ]
				++ lib.optional (group != null) "AXDisclosureTriangle:NSOutlineViewDisclosureButtonKey#${toString group.position}";
			# the row shows its keys on a button, between directional isolates
			expect = let keys = { "AXButton:⁦${testKeys}⁩" = { }; }; in
				if rowSwitch then {
					false = { "AXCheckBox:${ui}" = 0; };
					${testKeys} = keys // { "AXCheckBox:${ui}" = 1; };
				}
				else { ${testKeys} = keys; };
		};
	};

	# App Shortcuts are kept per app, as NSUserKeyEquivalents: menu title -> key equivalent, with
	# a submenu's title starting with an escape per menu, "\u001bFormat\u001bMake Plain Text"
	domainOf = app: if app == "All Applications" then "NSGlobalDomain" else app;
	menuKeys = app: items:
		let
			escape = builtins.fromJSON ''"\u001b"'';
			title = path: let menus = lib.splitString "->" path; in
				if lib.length menus == 1 then path else lib.concatMapStrings (menu: escape + menu) menus;
			# cfprefsd puts a sandboxed app's preferences in its container
			domain = lib.escapeShellArg (domainOf app);
		in
		"/usr/bin/defaults write ${domain} NSUserKeyEquivalents -dict "
		+ lib.concatStringsSep " " (lib.mapAttrsToList (path: keys:
			"${lib.escapeShellArg (title path)} ${lib.escapeShellArg (shortcuts.keyEquivalent keys)}") items);

	# the rows of one sidebar category: { <option> = [ "<row>" <id> ]; }. Test keys are ⌃⌥⇧⌘ and
	# a letter or digit picked by the id, unique within a category.
	rowsOf = { category, sidebar, group ? null, verifiable ? true }: rows: lib.mapAttrs (_: row: shortcut {
		inherit category sidebar group verifiable;
		ui = lib.elemAt row 0;
		id = lib.elemAt row 1;
		testKeys = "⌃⌥⇧⌘" + lib.elemAt (lib.stringToCharacters "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
			(lib.mod (lib.elemAt row 1) 36);
	}) rows;
in
{
	keyRepeatRate = setting {
		ui = [ "System Settings" "Keyboard" "Key repeat rate" ];
		description = "Time between repeats, in 15 ms steps: lower is faster. System Settings offers 120, 90, 60, 30, 12, 6 and 2. Takes effect after logging out.";
		storage = global "KeyRepeat";
		value = number { min = 1; max = 120; };
	};

	delayUntilRepeat = setting {
		ui = [ "System Settings" "Keyboard" "Delay until repeat" ];
		description = "Time before a held key repeats, in 15 ms steps: lower is shorter. System Settings offers 120, 94, 68, 35, 25 and 15. Takes effect after logging out.";
		storage = global "InitialKeyRepeat";
		value = number { min = 10; max = 120; };
	};

	pressGlobeKeyTo = setting {
		ui = [ "System Settings" "Keyboard" "Press 🌐︎ key to" ];
		storage = user "com.apple.HIToolbox" "AppleFnUsageType";
		value = enum {
			"Do Nothing" = 0;
			"Change Input Source" = 1;
			"Show Emoji & Symbols" = 2;
			"Start Dictation (Press 🌐︎ Twice)" = 3;
		};
		verify = {
			inherit pane;
			expect = {
				"Show Emoji & Symbols" = { "AXPopUpButton:Press 🌐︎ key to" = "Show Emoji & Symbols"; };
				"Change Input Source" = { "AXPopUpButton:Press 🌐︎ key to" = "Change Input Source"; };
			};
		};
	};

	keyboardNavigation = switch {
		ui = [ "Keyboard navigation" ];
		storage = global "AppleKeyboardUIMode";
		value = storedAs { true = 2; false = 0; } bool;
	};

	useF1F2EtcKeysAsStandardFunctionKeys = setting {
		ui = [ "System Settings" "Keyboard" "Keyboard Shortcuts…" "Function Keys" "Use F1, F2, etc. keys as standard function keys" ];
		storage = global "com.apple.keyboard.fnState";
		value = bool;
	};

	textInput = {
		automaticallySwitchToADocumentsInputSource = setting {
			ui = [ "System Settings" "Keyboard" "Text Input" "Input Sources" "Edit…" "Automatically switch to a document’s input source" ];
			storage = user "com.apple.HIToolbox" "AppleGlobalTextInputProperties";
			value = inDict "TextInputGlobalPropertyPerContextInput" bool;
			canUnset = false;
		};

		inputSources = setting {
			ui = [ "System Settings" "Keyboard" "Text Input" "Input Sources" "Edit…" "All Input Sources" ];
			description = ''
				The keyboard layouts and input methods to have, by input source id, e.g.
				[ "com.apple.keylayout.US" "com.apple.keylayout.ABC" ]; the others are removed.
				`nix run .#current` lists the ones in use.
			'';
			storage = user "com.apple.HIToolbox" "AppleEnabledInputSources";
			value = strings // { read = { inputSources = true; }; };
			canUnset = false;
			behaviors = [ (appliesThrough live.inputSources) ];
		};

		correctSpellingAutomatically = setting {
			ui = [ "System Settings" "Keyboard" "Text Input" "Input Sources" "Edit…" "Correct spelling automatically" ];
			storage = {
				native = global "NSAutomaticSpellingCorrectionEnabled";
				web = global "WebAutomaticSpellingCorrectionEnabled";
			};
			value = storedAs { true = { native = true; web = true; }; false = { native = false; web = false; }; } bool;
			verify = {
				inherit pane;
				open = [ "Edit…" ];
				expect = {
					true = { "AXCheckBox:Correct spelling automatically" = 1; };
					false = { "AXCheckBox:Correct spelling automatically" = 0; };
				};
			};
		};

		capitalizeWordsAutomatically = textInput "Capitalize words automatically" (global "NSAutomaticCapitalizationEnabled");
		showInlinePredictiveText = textInput "Show inline predictive text" (global "NSAutomaticInlinePredictionEnabled");
		showSuggestedReplies = textInput "Show suggested replies" (global "NSSmartReplyEnabled");
		addPeriodWithDoubleSpace = textInput "Add period with double-space" (global "NSAutomaticPeriodSubstitutionEnabled");

		useSmartQuotesAndDashes = setting {
			ui = [ "System Settings" "Keyboard" "Text Input" "Input Sources" "Edit…" "Use smart quotes and dashes" ];
			storage = {
				quotes = global "NSAutomaticQuoteSubstitutionEnabled";
				dashes = global "NSAutomaticDashSubstitutionEnabled";
			};
			value = storedAs { true = { quotes = true; dashes = true; }; false = { quotes = false; dashes = false; }; } bool;
			verify = {
				inherit pane;
				open = [ "Edit…" ];
				expect = {
					true = { "AXCheckBox:Use smart quotes and dashes" = 1; };
					false = { "AXCheckBox:Use smart quotes and dashes" = 0; };
				};
			};
		};
	};

	keyboardShortcuts = let
		dock = { category = "Launchpad & Dock"; sidebar = "Dock shortcuts"; };
		display = { category = "Display"; sidebar = "Display shortcuts"; };
		missionControl = { category = "Mission Control"; sidebar = "Mission Control shortcuts"; };
		windows = { category = "Windows"; sidebar = "Window management shortcuts"; };
		keyboard = { category = "Keyboard"; sidebar = "Keyboard shortcuts"; };
		inputSources = { category = "Input Sources"; sidebar = "Input Sources shortcuts"; };
		screenshots = { category = "Screenshots"; sidebar = "Screenshots shortcuts"; };
		spotlight = { category = "Spotlight"; sidebar = "Spotlight shortcuts"; };
		accessibility = { category = "Accessibility"; sidebar = "Accessibility shortcuts"; };
		appShortcuts = { category = "App Shortcuts"; sidebar = "Application shortcuts"; };
		inGroup = category: position: name: category // { group = { inherit position name; }; };
		inGroupSwitchedAsOne = category: position: name: category // { group = { inherit position name; switches = false; }; };
	in {
		launchpadAndDock = rowsOf dock {
			turnDockHidingOnOff = [ "Turn Dock hiding on/off" 52 ];
		};

		display = rowsOf display {
			decreaseDisplayBrightness = [ "Decrease display brightness" 53 ];
			increaseDisplayBrightness = [ "Increase display brightness" 54 ];
		};

		# Mission Control, Application windows and Show Desktop are in Desktop & Dock
		missionControl = rowsOf missionControl {
			showNotificationCenter = [ "Show Notification Center" 163 ];
			turnDoNotDisturbOnOff = [ "Turn Do Not Disturb on/off" 175 ];
			turnStageManagerOnOff = [ "Turn Stage Manager on/off" 222 ];
			quickNote = [ "Quick Note" 190 ];
			gameOverlay = [ "Game Overlay" 260 ];
		} // rowsOf (inGroup missionControl 1 "Mission Control") {
			moveLeftASpace = [ "Move left a Space" 79 ];
			moveRightASpace = [ "Move right a Space" 81 ];
			switchToDesktop1 = [ "Switch to Desktop 1" 118 ];
		# System Settings lists a row per desktop that exists
		} // rowsOf (inGroup missionControl 1 "Mission Control" // { verifiable = false; })
			(lib.listToAttrs (lib.genList (n: lib.nameValuePair "switchToDesktop${toString (n + 2)}"
				[ "Switch to Desktop ${toString (n + 2)}" (119 + n) ]) 15));

		windows = rowsOf (inGroup windows 1 "General") {
			minimize = [ "Minimize" 233 ];
			zoom = [ "Zoom" 235 ];
			fill = [ "Fill" 237 ];
			center = [ "Center" 238 ];
			returnToPreviousSize = [ "Return to Previous Size" 239 ];
		} // rowsOf (inGroup windows 2 "Halves") {
			tileLeftHalf = [ "Tile Left Half" 240 ];
			tileRightHalf = [ "Tile Right Half" 241 ];
			tileTopHalf = [ "Tile Top Half" 242 ];
			tileBottomHalf = [ "Tile Bottom Half" 243 ];
		} // rowsOf (inGroup windows 3 "Quarters") {
			tileTopLeftQuarter = [ "Tile Top Left Quarter" 244 ];
			tileTopRightQuarter = [ "Tile Top Right Quarter" 245 ];
			tileBottomLeftQuarter = [ "Tile Bottom Left Quarter" 246 ];
			tileBottomRightQuarter = [ "Tile Bottom Right Quarter" 247 ];
		} // rowsOf (inGroup windows 4 "Arrange") {
			arrangeLeftAndRight = [ "Arrange Left and Right" 248 ];
			arrangeRightAndLeft = [ "Arrange Right and Left" 249 ];
			arrangeTopAndBottom = [ "Arrange Top and Bottom" 250 ];
			arrangeBottomAndTop = [ "Arrange Bottom and Top" 251 ];
			arrangeInQuarters = [ "Arrange in Quarters" 256 ];
		} // rowsOf (inGroup windows 5 "Full Screen Tile") {
			fullScreenTileLeft = [ "Full Screen Tile Left" 257 ];
			fullScreenTileRight = [ "Full Screen Tile Right" 258 ];
		};

		keyboard = rowsOf keyboard {
			changeTheWayTabMovesFocus = [ "Change the way Tab moves focus" 13 ];
			turnKeyboardAccessOnOrOff = [ "Turn keyboard access on or off" 12 ];
			moveFocusToTheMenuBar = [ "Move focus to the menu bar" 7 ];
			moveFocusToTheDock = [ "Move focus to the Dock" 8 ];
			moveFocusToActiveOrNextWindow = [ "Move focus to active or next window" 9 ];
			moveFocusToTheWindowToolbar = [ "Move focus to the window toolbar" 10 ];
			moveFocusToTheFloatingWindow = [ "Move focus to the floating window" 11 ];
			moveFocusToNextWindow = [ "Move focus to next window" 27 ];
			moveFocusToStatusMenus = [ "Move focus to status menus" 57 ];
			showContextualMenu = [ "Show contextual menu" 159 ];
		};

		inputSources = rowsOf inputSources {
			selectThePreviousInputSource = [ "Select the previous input source" 60 ];
			selectNextSourceInInputMenu = [ "Select next source in Input menu" 61 ];
		};

		screenshots = rowsOf screenshots {
			savePictureOfScreenAsAFile = [ "Save picture of screen as a file" 28 ];
			copyPictureOfScreenToTheClipboard = [ "Copy picture of screen to the clipboard" 29 ];
			savePictureOfSelectedAreaAsAFile = [ "Save picture of selected area as a file" 30 ];
			copyPictureOfSelectedAreaToTheClipboard = [ "Copy picture of selected area to the clipboard" 31 ];
			screenshotAndRecordingOptions = [ "Screenshot and recording options" 184 ];
			askSiriAboutSelectedArea = [ "Ask Siri about selected area" 261 ];
			askSiriAboutActiveWindow = [ "Ask Siri about active window" 263 ];
		};

		spotlight = rowsOf spotlight {
			showSpotlightSearch = [ "Show Spotlight search" 64 ];
			showFinderSearchWindow = [ "Show Finder search window" 65 ];
			showApps = [ "Show Apps" 160 ];
		};

		services = setting {
			ui = [ "System Settings" "Keyboard" "Keyboard Shortcuts…" "Services" ];
			description = ''
				Services, on or off, or on with keys such as "⌘⇧T", by the id macOS keeps them under:
				"<app's bundle identifier> - <menu title> - <method>", e.g.
				{ "com.apple.Terminal - New Terminal at Folder - newTerminalAtFolder" = "⌘⇧T"; }.
				Services left out are left as they are; `nix run .#current` lists the ones that were
				changed in System Settings.
			'';
			storage = user "pbs" "NSServicesStatus";
			value = {
				kind = "services";
				read = { services = true; inherit (shortcuts) names; };
				type = lib.types.attrsOf (lib.types.either lib.types.bool shortcuts.type);
				choices = [];
				examples = [ { "com.apple.Terminal - New Terminal at Folder - newTerminalAtFolder" = "⌘⇧T"; } ];
				encode = keys: services: lib.optional (services != { }) (ops.mergeDict keys.value (lib.mapAttrs (_: choice:
					let
						on = choice != false;
					in
					{
						enabled_context_menu = on;
						enabled_services_menu = on;
						presentation_modes = { ContextMenu = on; ServicesMenu = on; };
					} // lib.optionalAttrs (lib.isString choice) { key_equivalent = shortcuts.keyEquivalent choice; }
				) services));
				fromName = builtins.fromJSON;
			};
			# unset would reset every service
			canUnset = false;
			# the pasteboard server keeps the services; restarting it would lose the clipboard
			behaviors = [ (_: plan: plan ++ [ (ops.afterwards "/System/Library/CoreServices/pbs -update") ]) ];
			verify = {
				inherit pane;
				open = [ "AXButton:Keyboard Shortcuts…" "click:Services shortcuts" "AXDisclosureTriangle:NSOutlineViewDisclosureButtonKey#1" ];
				expect = {
					${builtins.toJSON { "com.apple.Automator - Create Service - makeNewServiceWithPasteboard" = "⌃⌥⇧⌘S"; }} = {
						"AXCheckBox:Create Service" = 1;
						"AXButton:⁦⌃⌥⇧⌘S⁩" = { };
					};
					${builtins.toJSON { "com.apple.Automator - Create Service - makeNewServiceWithPasteboard" = false; }} = {
						"AXCheckBox:Create Service" = 0;
					};
				};
			};
		};

		appShortcuts = rowsOf (inGroup appShortcuts 1 "All Applications") {
			showHelpMenu = [ "Show Help menu" 98 ];
		} // {
			menuItems = setting {
				ui = [ "System Settings" "Keyboard" "Keyboard Shortcuts…" "App Shortcuts" ];
				description = ''
					Keys for menu items, per app by bundle identifier or "All Applications", by the menu
					item's title; a title in a submenu is written with its menus, "Format->Font->Bold".
					Keys are written like "⌘⇧S" (see Keyboard Shortcuts…). Each app listed gets exactly
					these; apps left out keep theirs, e.g.
					{ "com.apple.TextEdit" = { "Make Plain Text" = "⌘⇧T"; }; }.
				'';
				storage = {
					keys = global "NSUserKeyEquivalents" // { domain = "~/Library/Preferences/<application>"; };
					apps = user "com.apple.universalaccess" "com.apple.custommenu.apps";
				};
				value = {
					kind = "applications";
					read = { appShortcuts = true; inherit (shortcuts) names; };
					type = lib.types.attrsOf (lib.types.attrsOf shortcuts.type);
					choices = [];
					examples = [ { "com.apple.TextEdit" = { "Make Plain Text" = "⌘⇧T"; }; } ];
					encode = keys: apps: lib.optionals (apps != { }) (
						lib.mapAttrsToList (app: items: ops.run (menuKeys app items)) apps
						# System Settings lists the apps that have some
						++ [ (ops.setMembers keys.apps (lib.mapAttrs' (app: _: lib.nameValuePair (domainOf app) true) apps)) ]
					);
					fromName = builtins.fromJSON;
				};
				# unset has no single key to delete
				canUnset = false;
				verify = {
					inherit pane;
					open = [ "AXButton:Keyboard Shortcuts…" "click:Application shortcuts" "AXDisclosureTriangle:NSOutlineViewDisclosureButtonKey#2" ];
					expect = {
						${builtins.toJSON { "com.apple.TextEdit" = { "Format->Make Plain Text" = "⌃⌥⇧⌘T"; }; }} = {
							"AXHeading:TextEdit.app" = { };
							"AXButton:⁦⌃⌥⇧⌘T⁩" = { };
						};
					};
				};
			};
		};

		# Zoom's shortcuts are in Accessibility > Zoom
		accessibility = rowsOf accessibility {
			invertColors = [ "Invert colors" 21 ];
			showAccessibilityControls = [ "Show Accessibility controls" 162 ];
			turnSpeakItemUnderThePointerOnOrOff = [ "Turn speak item under the pointer on or off" 231 ];
			turnSpeakSelectionOnOrOff = [ "Turn speak selection on or off" 230 ];
			turnTypingFeedbackOnOrOff = [ "Turn typing feedback on or off" 232 ];
			turnVoiceOverOnOrOff = [ "Turn VoiceOver on or off" 59 ];
		} // rowsOf (inGroupSwitchedAsOne accessibility 1 "Contrast") {
			increaseContrast = [ "Increase contrast" 25 ];
			decreaseContrast = [ "Decrease contrast" 26 ];
		} // rowsOf (inGroupSwitchedAsOne accessibility 2 "Live Captions") {
			turnLiveCaptionsOnOrOff = [ "Turn Live Captions on or off" 215 ];
			pauseOrResumeTranscription = [ "Pause or resume transcription" 216 ];
			turnTypeToSpeakOnOrOff = [ "Turn type to speak on or off" 217 ];
			switchBetweenTranscribingComputerAudioAndMicrophone = [ "Switch between transcribing computer audio and microphone" 218 ];
			turnKeepOnscreenOnOrOff = [ "Turn keep onscreen on or off" 219 ];
		} // rowsOf (inGroupSwitchedAsOne accessibility 3 "Live Speech") {
			turnLiveSpeechOnOrOff = [ "Turn Live Speech on or off" 225 ];
			toggleVisibility = [ "Toggle visibility" 226 ];
			pauseOrResumeSpeech = [ "Pause or resume speech" 227 ];
			cancelSpeech = [ "Cancel speech" 228 ];
			hideOrShowPhrases = [ "Hide or show phrases" 229 ];
		};
	};
}
