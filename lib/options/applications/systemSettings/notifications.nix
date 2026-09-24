{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user bool enum snapshot restarts appliesThrough;

	pane = "com.apple.settings.notifications";
	domain = "~/Library/Group Containers/group.com.apple.usernoted/Library/Preferences/group.com.apple.usernoted";
	usernoted = user domain;
	restartsUsernoted = restarts "usernoted";

	# dnd_prefs is stored inverted: dndDisplaySleep is true when notifications aren't allowed.
	dndPreference = entry: allowed:
		let
			q = lib.escapeShellArg;
			path = ''"$HOME"/${q (lib.removePrefix "~/" domain)}'';
		in
		''f=$(/usr/bin/mktemp) && /usr/bin/defaults export ${path} - | /usr/bin/plutil -extract dnd_prefs raw -o - - | /usr/bin/base64 -D > "$f" && /usr/bin/plutil -replace ${entry} -bool ${lib.boolToString (!allowed)} "$f" && /usr/bin/defaults write ${path} dnd_prefs -data "$(/usr/bin/xxd -p "$f" | /usr/bin/tr -d '\n')" || echo ${q "nix-plist-manager: failed: setting ${entry} in dnd_prefs"} >&2; /bin/rm -f "$f"'';

	allow = { ui, entry, control }: setting {
		ui = [ "System Settings" "Notifications" "Allow notifications" ui ];
		storage = usernoted "dnd_prefs";
		value = bool;
		canUnset = false;
		behaviors = [ (appliesThrough (dndPreference entry)) restartsUsernoted ];
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
	notificationCenter = {
		showPreviews = setting {
			ui = [ "System Settings" "Notifications" "Show previews" ];
			storage = usernoted "content_visibility";
			value = enum { Always = 3; "When Unlocked" = 2; Never = 1; };
			behaviors = [ restartsUsernoted ];
			verify = {
				inherit pane;
				expect = {
					Always = { "AXPopUpButton:show-previews" = "Always"; };
					"When Unlocked" = { "AXPopUpButton:show-previews" = "When Unlocked"; };
				};
			};
		};

		summarizeNotifications = setting {
			ui = [ "System Settings" "Notifications" "Summarize notifications" ];
			storage = usernoted "summarize_previews";
			value = bool;
			behaviors = [ restartsUsernoted ];
		};
	};

	allowNotifications = {
		whenTheDisplayIsSleeping = allow { ui = "When the display is sleeping"; entry = "dndDisplaySleep"; control = "allow-when-sleeping"; };
		whenTheScreenIsLocked = allow { ui = "When the screen is locked"; entry = "dndDisplayLock"; control = "allow-when-locked"; };

		whenMirroringOrSharingTheDisplay = setting {
			ui = [ "System Settings" "Notifications" "Allow notifications" "When mirroring or sharing the display" ];
			storage = usernoted "dnd_prefs";
			value = enum { "Allow Notifications" = true; "Notifications Off" = false; };
			canUnset = false;
			behaviors = [ (appliesThrough (choice: dndPreference "dndMirrored" (choice == "Allow Notifications"))) restartsUsernoted ];
			verify = {
				inherit pane;
				expect = {
					"Allow Notifications" = { "AXPopUpButton:allow-when-sharing" = "Allow Notifications"; };
					"Notifications Off" = { "AXPopUpButton:allow-when-sharing" = "Notifications Off"; };
				};
			};
		};
	};

	applications = setting {
		ui = [ "System Settings" "Notifications" "Application Notifications" ];
		storage.apps = usernoted "apps";
		value = snapshot;
		behaviors = [ restartsUsernoted ];
	};
}
