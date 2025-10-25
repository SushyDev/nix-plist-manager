{ lib, commandsLib, pathLib, typesLib, configLib, }:
let
	byHostGlobalPreferences = pathLib.generatePath true true ".GlobalPreferences";
in
{
	appearance = rec {
		path = [ "System Settings" "Appearance" "Appearance" ];
		description = "";

		mapping = {
			"unset" = {
				command = lib.concatStrings [
					(commandsLib.defaults.delete "NSGlobalDomain" "AppleInterfaceStyleSwitchesAutomatically") " && \\\n"
					(commandsLib.defaults.delete byHostGlobalPreferences "AppleInterfaceStyle")
				];
			};
			"Light" = {
				command = commandsLib.osaScript "tell application \"System Events\" to tell appearance preferences to set dark mode to false";
			};
			"Dark" = {
				command = commandsLib.osaScript "tell application \"System Events\" to tell appearance preferences to set dark mode to true";
			};
			"Auto" = {
				command = commandsLib.defaults.write "NSGlobalDomain" "AppleInterfaceStyleSwitchesAutomatically" "bool" "true";
			};
		};

		default = null;

		option = lib.mkOption {
			inherit description default;
			type = typesLib.nullOrMapping mapping;
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
		path = [ "System Settings" "Appearance" "Accent Color" ];
		description = "";

		mapping = {
			"unset" = {
				command = lib.concatStrings [
					(commandsLib.defaults.delete byHostGlobalPreferences "AppleAccentColor") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
			"Graphite" = {
				command = lib.concatStrings [
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAccentColor"  "int" "-1") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
			"Red" = {
				command = lib.concatStrings [
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAccentColor"  "int" "0") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
			"Orange" = {
				command = lib.concatStrings [
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAccentColor"  "int" "1") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
			"Yellow" = {
				command = lib.concatStrings [
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAccentColor"  "int" "2") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
			"Green" = {
				command = lib.concatStrings [
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAccentColor"  "int" "3") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
			"Blue" = {
				command = lib.concatStrings [
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAccentColor"  "int" "4") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
			"Purple" = {
				command = lib.concatStrings [
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAccentColor"  "int" "5") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
			"Pink" = {
				command = lib.concatStrings [
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAccentColor"  "int" "6") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
			"Multicolor" = {
				command = lib.concatStrings [
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAccentColor"  "int" "7") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
		};

		default = null;

		option = lib.mkOption {
			inherit description default;
			type = typesLib.nullOrMapping mapping;
		};

		config = {
			perUser = true;
			command = configLib.commandMapping mapping;
		};
	};

	# highlightColor

	sidebarIconSize = rec {
		path = [ "System Settings" "Appearance" "Sidebar Icon Size" ];
		description = "";

		mapping = 
			let
				optionName = "NSTableViewDefaultSizeMode";
			in
			{
				"unset" = {
					command = commandsLib.defaults.delete byHostGlobalPreferences optionName;
				};
				"Small" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "int" "1";
				};
				"Medium" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "int" "2";
				};
				"Large" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "int" "3";
				};
			};

		default = null;

		option = lib.mkOption {
			inherit description default;
			type = typesLib.nullOrMapping mapping;
		};

		config = {
			perUser = true;
			command = configLib.commandMapping mapping;
		};
	};

	allowWallpaperTintingInWindows = rec {
		path = [ "System Settings" "Appearance" "Allow wallpaper tinting in windows" ];
		description = "";

		mapping = 
			let
				optionName = "AppleReduceDesktopTinting";
			in
			{
				"unset" = {
					command = commandsLib.defaults.delete byHostGlobalPreferences optionName;
				};
				"true" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "bool" "false";
				};
				"false" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "bool" "true";
				};
			};

		default = null;

		option = lib.mkOption {
			inherit description default;
			type = typesLib.nullOrBoolOrUnset;
		};

		config = {
			perUser = true;
			command = configLib.commandNullOrBoolOrUnset mapping;
		};
	};

	showScrollBars = rec {
		path = [ "System Settings" "Appearance" "Show scroll bars" ];
		description = "";

		mapping = 
			let
				optionName = "AppleShowScrollBars";
			in
			{
				"unset" = {
					command = commandsLib.defaults.delete byHostGlobalPreferences optionName;
				};
				"Automatically based on mouse or trackpad" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "Automatic";
				};
				"When scrolling" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "WhenScrolling";
				};
				"Always" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "Always";
				};
			};

		default = null;

		option = lib.mkOption {
			inherit description default;
			type = typesLib.nullOrMapping mapping;
		};

		config = {
			perUser = true;
			command = configLib.commandMapping mapping;
		};
	};

	clickInTheScrollBarTo = rec {
		path = [ "System Settings" "Appearance" "Click in the scroll bar to" ];
		description = "";

		mapping = 
			let
				optionName = "AppleScrollerPagingBehavior";
			in
			{
				"unset" = {
					command = commandsLib.defaults.delete byHostGlobalPreferences optionName;
				};
				"Jump to the next page" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "int" "0";
				};
				"Jump to the spot that's clicked" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "int" "1";
				};
			};

		default = null;

		option = lib.mkOption {
			inherit description default;
			type = typesLib.nullOrMapping mapping;
		};

		config = {
			perUser = true;
			command = configLib.commandMapping mapping;
		};
	};
}
