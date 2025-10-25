{ lib, ... }:
{
	softwareUpdate = {
		automaticallyDownloadNewUpdatesWhenAvailable = rec {
			path = [ "System Settings" "General" "Software Update" "Download new updates when available" ];
			description = "";

			mapping = {
				"unset" = {
					command = "defaults delete /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload";
				};
				"true" = {
					command = "defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true";
				};
				"false" = {
					command = "defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false";
				};
			};

			default = null;

			option = lib.mkOption {
				inherit description default;
				type = lib.types.nullOr (lib.types.either lib.types.bool (lib.types.enum [ "unset" ]));
			};

			config = {
				perUser = false;
				command = value:
					if builtins.isNull value then mapping."null".command
					else if value == true then mapping."true".command
					else mapping."false".command;
			};
		};

		automaticallyInstallMacOSUpdates = rec {
			path = [ "System Settings" "General" "Software Update" "Install macOS updates" ];
			description = "";

			mapping = {
				"unset" = {
					command = "defaults delete /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates";
				};
				"true" = {
					command = "defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool true";
				};
				"false" = {
					command = "defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false";
				};
			};

			default = null;

			option = lib.mkOption {
				inherit description default;
				type = lib.types.nullOr (lib.types.either lib.types.bool (lib.types.enum [ "unset" ]));
			};

			config = {
				perUser = false;
				command = value:
					if builtins.isNull value then mapping."null".command
					else if value == true then mapping."true".command
					else mapping."false".command;
			};
		};

		automaticallyInstallApplicationUpdatesFromTheAppStore = rec {
			path = [ "System Settings" "General" "Software Update" "Install application updates from the App Store" ];
			description = "";

			mapping = {
				"unset" = {
					command = "defaults delete /Library/Preferences/com.apple.commerce AutoUpdate";
				};
				"true" = {
					command = "defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool true";
				};
				"false" = {
					command = "defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool false";
				};
			};

			default = null;

			option = lib.mkOption {
				inherit description default;
				type = lib.types.nullOr (lib.types.either lib.types.bool (lib.types.enum [ "unset" ]));
			};

			config = {
				perUser = false;
				command = value:
					if builtins.isNull value then mapping."null".command
					else if value == true then mapping."true".command
					else mapping."false".command;
			};
		};

		automaticallyInstallSecurityResponseAndSystemFiles = rec {
			path = [ "System Settings" "General" "Software Update" "Install Security Response and system files" ];
			description = "";

			mapping = {
				"unset" = {
					command = "defaults delete /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall";
				};
				"true" = {
					command = "defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true";
				};
				"false" = {
					command = "defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool false";
				};
			};

			default = null;

			option = lib.mkOption {
				inherit description default;
				type = lib.types.nullOr (lib.types.either lib.types.bool (lib.types.enum [ "unset" ]));
			};

			config = {
				perUser = false;
				command = value:
					if builtins.isNull value then mapping."null".command
					else if value == true then mapping."true".command
					else mapping."false".command;
			};
		};
	};

	dateAndTime = {
		# TODO setTimeAndDateAutomatically
		# TODO source
		# TODO dateAndTime
		"24HourTime" = rec {
			path = [ "System" "Date & Time" "24-hour time" ];
			description = "";

			mapping = {
				"unset" = {
					command = "defaults delete ~/Library/Preferences/ByHost/.GlobalPreferences AppleICUForce24HourTime";
				};
				"true" = {
					command = "defaults write ~/Library/Preferences/ByHost/.GlobalPreferences AppleICUForce24HourTime -bool true";
				};
				"false" = {
					command = "defaults write ~/Library/Preferences/ByHost/.GlobalPreferences AppleICUForce24HourTime -bool false";
				};
			};

			default = null;

			option = lib.mkOption {
				inherit description default;
				type = lib.types.nullOr (lib.types.either lib.types.bool (lib.types.enum [ "unset" ]));
			};

			config = {
				perUser = true;
				command = value:
					if builtins.isNull value then mapping."null".command
					else if value == true then mapping."true".command
					else mapping."false".command;
			};
		};
		# TODO show24HourTimeOnLockScreen
		# TODO setTimeZoneAutomaticallyUsingCurrentLocation
		# TODO timeZone
		# TODO closestCity
	};
}
