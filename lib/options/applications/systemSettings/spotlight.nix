{ lib, settingsLib, ... }:
# EnabledPreferenceRules lists what's turned off, despite its name.
let
	inherit (settingsLib) setting user bool enum storedAs member members;

	pane = "com.apple.settings.search";
	rules = user "com.apple.Spotlight" "EnabledPreferenceRules";
	spotlight = user "com.apple.Spotlight";

	switch = { ui, storage, value ? bool, control ? ui }: setting {
		inherit storage value;
		ui = [ "System Settings" "Spotlight" ui ];
		verify = {
			inherit pane;
			expect = {
				true = { "AXCheckBox:${control}" = 1; };
				false = { "AXCheckBox:${control}" = 0; };
			};
		};
	};
in
{
	showRelatedContent = switch {
		ui = "Show Related Content";
		storage = rules;
		value = member { item = "Custom.relatedContents"; listedWhen = false; };
	};

	helpAppleImproveSearch = switch {
		ui = "Help Apple Improve Search";
		storage = user "com.apple.assistant.support" "Search Queries Data Sharing Status";
		value = storedAs { true = 1; false = 2; } bool;
	};

	searchResults = setting {
		ui = [ "System Settings" "Spotlight" "Search results" ];
		storage = rules;
		value = members {
			listedWhen = false;
			items = {
				appStore = "com.apple.AppStore";
				books = "com.apple.iBooksX";
				calculator = "com.apple.calculator";
				calendar = "com.apple.iCal";
				contacts = "com.apple.AddressBook";
				dictionary = "com.apple.Dictionary";
				games = "com.apple.games";
				mail = "com.apple.mail";
				messages = "com.apple.MobileSMS";
				music = "com.apple.Music";
				notes = "com.apple.Notes";
				phone = "com.apple.mobilephone";
				photos = "com.apple.Photos";
				podcasts = "com.apple.podcasts";
				reminders = "com.apple.reminders";
				safari = "com.apple.Safari";
				shortcuts = "com.apple.shortcuts";
				systemSettings = "com.apple.systempreferences";
				tips = "com.apple.tips";
				voiceMemos = "com.apple.VoiceMemos";
				apps = "System.applications";
				files = "System.files";
				folders = "System.folders";
				iPhoneApps = "System.iphoneApps";
				menuItems = "System.menuItems";
			};
		};
	};

	resultsFromClipboard = switch {
		ui = "Results from Clipboard";
		storage = spotlight "PasteboardHistoryEnabled";
		control = "Results from Clipboard";
	};

	clipboardHistoryIsAvailableInSpotlight = setting {
		ui = [ "System Settings" "Spotlight" "Results from Clipboard" "Keep for" ];
		storage = spotlight "PasteboardHistoryTimeout";
		value = enum { "30 minutes" = 1800; "8 hours" = 28800; "7 days" = 604800; };
		verify = {
			inherit pane;
			expect = {
				"8 hours" = { "AXPopUpButton:Results from Clipboard" = "8 hours"; };
				"7 days" = { "AXPopUpButton:Results from Clipboard" = "7 days"; };
			};
		};
	};
}
