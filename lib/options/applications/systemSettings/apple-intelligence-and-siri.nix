{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user global bool enum shows;

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
				expect = shows.radio [ "Spoken Response" "Silent Response" ];
			};
		};
	};

	automaticVisualLookUp = setting {
		ui = [ "System Settings" "Apple Intelligence & Siri" "Automatic Visual Look Up" ];
		storage = global "SSPreferencesVisualLookUpInSSSEnabled";
		value = bool;
		verify = {
			inherit pane;
			expect = shows.checkbox "AXCheckBox:Automatic Visual Look Up";
		};
	};

	chatGpt.useExtension = setting {
		ui = [ "System Settings" "Apple Intelligence & Siri" "ChatGPT" "Use Extension" ];
		storage = user "com.apple.siri.generativeassistantsettings" "isEnabled";
		value = bool;
		verify = {
			inherit pane;
			open = [ "ChatGPT" ];
			expect = shows.checkbox "AXCheckBox:Use Extension";
		};
	};
}
