{ lib, settingsLib, ... }:
# Not covered: listening for "Siri" / "Hey Siri" (it needs voice training on the Mac), Language and
# Voice (they download assets), App Access (per app), and Opens To, Keep Conversations and
# Preview, which aren't kept in preferences.
let
	inherit (settingsLib) setting user global bool enum;

	pane = "com.apple.settings.siri";
in
{
	appleIntelligence = setting {
		ui = [ "System Settings" "Apple Intelligence & Siri" "Apple Intelligence" ];
		storage = user "com.apple.CloudSubscriptionFeatures.optIn" "10334750688";
		value = bool;
	};

	siri = {
		enable = setting {
			ui = [ "System Settings" "Apple Intelligence & Siri" "Siri" ];
			storage = user "com.apple.assistant.support" "Assistant Enabled";
			value = bool;
		};

		responses = setting {
			ui = [ "System Settings" "Apple Intelligence & Siri" "Responses" ];
			storage = user "com.apple.assistant.backedup" "Use device speaker for TTS";
			value = enum { "Spoken Response" = 2; "Silent Response" = 3; };
			verify = {
				inherit pane;
				open = [ "Responses" ];
				expect = {
					"Spoken Response" = { "AXRadioButton:Spoken Response" = 1; };
					"Silent Response" = { "AXRadioButton:Silent Response" = 1; };
				};
			};
		};
	};

	automaticVisualLookUp = setting {
		ui = [ "System Settings" "Apple Intelligence & Siri" "Automatic Visual Look Up" ];
		storage = global "SSPreferencesVisualLookUpInSSSEnabled";
		value = bool;
		verify = {
			inherit pane;
			expect = {
				true = { "AXCheckBox:Automatic Visual Look Up" = 1; };
				false = { "AXCheckBox:Automatic Visual Look Up" = 0; };
			};
		};
	};

	chatGpt.useExtension = setting {
		ui = [ "System Settings" "Apple Intelligence & Siri" "ChatGPT" "Use Extension" ];
		storage = user "com.apple.siri.generativeassistantsettings" "isEnabled";
		value = bool;
		verify = {
			inherit pane;
			open = [ "ChatGPT" ];
			expect = {
				true = { "AXCheckBox:Use Extension" = 1; };
				false = { "AXCheckBox:Use Extension" = 0; };
			};
		};
	};
}
