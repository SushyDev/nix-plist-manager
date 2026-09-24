{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user bool enum;

	shared = user "~/Library/Group Containers/group.com.apple.Journal/Library/Preferences/group.com.apple.Journal";
in
{
	addEntryTitle = setting {
		ui = [ "Journal" "Settings…" "General" "Add Entry Title" ];
		storage = shared "ADD_ENTRY_TITLE";
		value = enum { Always = 0; "Only for Moments" = 1; Never = 2; };
	};

	alwaysUseMomentDate = setting {
		ui = [ "Journal" "Settings…" "General" "Always Use Moment Date" ];
		storage = shared "ALWAYS_USE_MOMENT_DATE";
		value = bool;
	};

	getWritingPrompts = setting {
		ui = [ "Journal" "Settings…" "General" "Get Writing Prompts" ];
		storage = shared "showFollowupPrompts";
		value = bool;
	};
}
