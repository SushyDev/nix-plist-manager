{ lib }:
let
	osaScript = script: "/usr/bin/osascript -e ${lib.escapeShellArg script}";
in
{
	systemSettings = {
		general = {
			softwareUpdate = {
				automaticallyDownloadNewUpdatesWhenAvailable = rec {
					description = "System > Software Update > Download new updates when available";

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
						type = lib.types.nullOr lib.types.bool;
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
		};
	};
}

