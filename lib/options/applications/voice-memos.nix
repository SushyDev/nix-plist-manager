{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user bool enum;

	shared = user "~/Library/Group Containers/group.com.apple.VoiceMemos.shared/Library/Preferences/group.com.apple.VoiceMemos.shared";
in
{
	clearDeleted = setting {
		ui = [ "Voice Memos" "Settings…" "Clear Deleted" ];
		storage = shared "RCVoiceMemosRecentlyDeletedWindowKey";
		value = enum { Immediately = 0; "After 1 Day" = 1; "After 7 Days" = 7; "After 30 Days" = 30; Never = -1; };
	};

	audioQuality = setting {
		ui = [ "Voice Memos" "Settings…" "Audio Quality" ];
		storage = shared "RCVoiceMemosAudioQualityKey";
		value = enum { Lossy = 0; Lossless = 1; };
	};

	locationBasedNaming = setting {
		ui = [ "Voice Memos" "Settings…" "Location-based Naming" ];
		storage = shared "RCVoiceMemosUseLocationBasedNaming";
		value = bool;
	};
}
