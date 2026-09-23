{ lib, settingsLib, ... }:
# Keyboard brightness and backlight belong to the keyboard and change often, modifier keys are
# per keyboard, and the microphone follows what's connected, so none of them are here. The Input
# menu is in Menu Bar.
let
	inherit (settingsLib) setting global user bool storedAs enum number ops;

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
			value = bool // {
				encode = keys: enabled: [ (ops.mergeDict keys.value { TextInputGlobalPropertyPerContextInput = enabled; }) ];
			};
			canUnset = false;
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
}
