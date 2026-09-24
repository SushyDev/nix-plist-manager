{ lib, settingsLib, ... }:
# App permissions are kept in the TCC database, which SIP protects, and aren't here.
let
	inherit (settingsLib) setting user system file mkKey bool number appliesThrough ops;

	pane = "com.apple.settings.privacyAndSecurity";

	# Mac analytics consent, kept by the diagnostics submission service, as root
	diagnostics = name: mkKey {
		domain = "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory";
		inherit name;
		scope = "system";
	};

	# the authorization rule for System Settings' system-wide panes: shared means any user can
	# unlock them, otherwise only an administrator
	systemPreferencesRight = shared: lib.concatStringsSep "; " [
		"rule=$(/usr/bin/mktemp)"
		"/usr/bin/security authorizationdb read system.preferences > \"$rule\" 2>/dev/null"
		"/usr/bin/plutil -replace shared -bool ${lib.boolToString shared} \"$rule\""
		"/usr/bin/security authorizationdb write system.preferences < \"$rule\" >/dev/null 2>&1"
		"rm -f \"$rule\""
	];
in
{
	analyticsAndImprovements = {
		shareMacAnalytics = setting {
			ui = [ "System Settings" "Privacy & Security" "Analytics & Improvements" "Share Mac Analytics" ];
			storage = diagnostics "AutoSubmit";
			value = bool;
		};

		shareWithAppDevelopers = setting {
			ui = [ "System Settings" "Privacy & Security" "Analytics & Improvements" "Share with app developers" ];
			storage = diagnostics "ThirdPartyDataSubmit";
			value = bool;
		};
	};

	appleAdvertising.personalizedAds = setting {
		ui = [ "System Settings" "Privacy & Security" "Apple Advertising" "Personalized Ads" ];
		storage = user "com.apple.AdLib" "allowApplePersonalizedAdvertising";
		value = bool;
	};

	advanced = {
		requireAnAdministratorPasswordToAccessSystemWideSettings = setting {
			ui = [ "System Settings" "Privacy & Security" "Advanced…" "Require an administrator password to access system-wide settings" ];
			storage = file "security authorizationdb system.preferences";
			value = bool;
			canUnset = false;
			behaviors = [ (appliesThrough (required: systemPreferencesRight (!required))) ];
			verify = {
				inherit pane;
				open = [ "AXButton:Advanced…" ];
				expect = {
					true = { "AXCheckBox:PreferenceLock_Toggle" = 1; };
					false = { "AXCheckBox:PreferenceLock_Toggle" = 0; };
				};
			};
		};

		# kept in seconds; 0 turns it off
		logOutAutomaticallyAfterInactivity = setting {
			ui = [ "System Settings" "Privacy & Security" "Advanced…" "Log out automatically after inactivity" ];
			description = "Minutes of inactivity before logging out; 0 doesn't log out.";
			storage = system ".GlobalPreferences" "com.apple.autologout.AutoLogOutDelay";
			value = number { min = 0; max = 960; } // {
				encode = keys: minutes: [ (ops.write keys.value (minutes * 60)) ];
			};
			verify = {
				inherit pane;
				open = [ "AXButton:Advanced…" ];
				expect = {
					"0" = { "AXCheckBox:AutoLogout_Toggle" = 0; };
					"60" = { "AXCheckBox:AutoLogout_Toggle" = 1; "AXIncrementor:Log out after" = 60; };
				};
			};
		};
	};
}
