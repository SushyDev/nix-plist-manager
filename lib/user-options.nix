{ lib, config }:
let
	osaScript = script: "osascript -e ${lib.escapeShellArg script}";
in
{
	systemSettings = {
		appearance = {
			appearance = rec {
					description = "Appearance > Appearance";

					mapping = {
						"unset" = {
							command = "defaults delete NSGlobalDomain AppleInterfaceStyle";
						};
						"Light" = {
							command = osaScript "tell application \"System Events\" to tell appearance preferences to set dark mode to false";
						};
						"Dark" = {
							command = osaScript "tell application \"System Events\" to tell appearance preferences to set dark mode to true";
						};
						"Auto" = {
							command = "defaults write NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -bool true";
						};
					};

					default = null;

					option = lib.mkOption {
						inherit description default;
						type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
					};

					config = {
						perUser = true;
						command = value:
							let
								cmd = if value == null then mapping."null".command
									else mapping.${lib.escapeShellArg value}.command;
							in
							cmd;
					};
				};

			accentColor = rec {
					description = "Appearance > Accent Color";

					mapping = {
						"unset" = {
							command = "defaults delete NSGlobalDomain AppleAccentColor";
						};
						"Graphite" = {
							command = ''
								defaults write ~sushy/Library/Preferences/ByHost/.GlobalPreferences AppleAccentColor -int -1 && \
								notifyutil -p AppleColorPreferencesChangedNotification && \
								notifyutil -p AppleAquaColorVariantChanged
							'';
						};
						"Red" = {
							command = ''
								defaults write ~sushy/Library/Preferences/ByHost/.GlobalPreferences AppleAccentColor -int 0 && \
								notifyutil -p AppleColorPreferencesChangedNotification && \
								notifyutil -p AppleAquaColorVariantChanged
							'';
						};
						"Orange" = {
							command = ''
								defaults write ~sushy/Library/Preferences/ByHost/.GlobalPreferences AppleAccentColor -int 1 && \
								notifyutil -p AppleColorPreferencesChangedNotification && \
								notifyutil -p AppleAquaColorVariantChanged
							'';
						};
						"Yellow" = {
							command = ''
								defaults write ~sushy/Library/Preferences/ByHost/.GlobalPreferences AppleAccentColor -int 2 && \
								notifyutil -p AppleColorPreferencesChangedNotification && \
								notifyutil -p AppleAquaColorVariantChanged
							'';
						};
						"Green" = {
							command = ''
								defaults write ~sushy/Library/Preferences/ByHost/.GlobalPreferences AppleAccentColor -int 3 && \
								notifyutil -p AppleColorPreferencesChangedNotification && \
								notifyutil -p AppleAquaColorVariantChanged
							'';
						};
						"Blue" = {
							command = ''
								defaults write ~sushy/Library/Preferences/ByHost/.GlobalPreferences AppleAccentColor -int 4 && \
								notifyutil -p AppleColorPreferencesChangedNotification && \
								notifyutil -p AppleAquaColorVariantChanged
							'';
						};
						"Purple" = {
							command = ''
								defaults write ~sushy/Library/Preferences/ByHost/.GlobalPreferences AppleAccentColor -int 5 && \
								notifyutil -p AppleColorPreferencesChangedNotification && \
								notifyutil -p AppleAquaColorVariantChanged
							'';
						};
						"Pink" = {
							command = ''
								defaults write ~sushy/Library/Preferences/ByHost/.GlobalPreferences AppleAccentColor -int 6 && \
								notifyutil -p AppleColorPreferencesChangedNotification && \
								notifyutil -p AppleAquaColorVariantChanged
							'';
						};
						"Multicolor" = {
							command = ''
								defaults write ~sushy/Library/Preferences/ByHost/.GlobalPreferences AppleAccentColor -int 7 && \
								notifyutil -p AppleColorPreferencesChangedNotification && \
								notifyutil -p AppleAquaColorVariantChanged
							'';
						};
					};

					default = null;

					option = lib.mkOption {
						inherit description default;
						type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
					};

					config = {
						perUser = true;
						command = value:
							let
								cmd = if value == null then mapping."null".command
									else mapping.${lib.escapeShellArg value}.command;
							in
							cmd;
					};
				};
		};
	};
}

