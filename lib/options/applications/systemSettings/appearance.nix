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

	liquidGlass = rec {
		path = [ "System Settings" "Appearance" "Liquid Glass" ];
		description = "Controls the Liquid Glass style. Clear is more transparent; Tinted increases opacity and adds more contrast.";

		mapping =
			let
				optionName = "NSGlassDiffusionSetting";
			in
			{
				"unset" = {
					command = commandsLib.defaults.delete byHostGlobalPreferences optionName;
				};
				"Clear" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "bool" "false";
				};
				"Tinted" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "bool" "true";
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

	accentColor = rec {
		path = [ "System Settings" "Appearance" "Theme" "Color" ];
		description = "The accent color used for buttons, menus, and highlights. AppleAquaColorVariant is a legacy companion key: 6 for Graphite, 1 for all other colors.";

		mapping = {
			"unset" = {
				command = lib.concatStrings [
					(commandsLib.defaults.delete byHostGlobalPreferences "AppleAccentColor") " && \\\n"
					(commandsLib.defaults.delete byHostGlobalPreferences "AppleAquaColorVariant") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
			"Graphite" = {
				command = lib.concatStrings [
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAccentColor"      "int" "-1") " && \\\n"
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAquaColorVariant" "int" "6") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
			"Red" = {
				command = lib.concatStrings [
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAccentColor"      "int" "0") " && \\\n"
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAquaColorVariant" "int" "1") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
			"Orange" = {
				command = lib.concatStrings [
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAccentColor"      "int" "1") " && \\\n"
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAquaColorVariant" "int" "1") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
			"Yellow" = {
				command = lib.concatStrings [
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAccentColor"      "int" "2") " && \\\n"
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAquaColorVariant" "int" "1") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
			"Green" = {
				command = lib.concatStrings [
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAccentColor"      "int" "3") " && \\\n"
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAquaColorVariant" "int" "1") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
			"Blue" = {
				command = lib.concatStrings [
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAccentColor"      "int" "4") " && \\\n"
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAquaColorVariant" "int" "1") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
			"Purple" = {
				command = lib.concatStrings [
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAccentColor"      "int" "5") " && \\\n"
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAquaColorVariant" "int" "1") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
			"Pink" = {
				command = lib.concatStrings [
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAccentColor"      "int" "6") " && \\\n"
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAquaColorVariant" "int" "1") " && \\\n"
					(commandsLib.notifyUtilPost "AppleColorPreferencesChangedNotification") " && \\\n"
					(commandsLib.notifyUtilPost "AppleAquaColorVariantChanged")
				];
			};
			"Multicolor" = {
				command = lib.concatStrings [
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAccentColor"      "int" "7") " && \\\n"
					(commandsLib.defaults.write byHostGlobalPreferences "AppleAquaColorVariant" "int" "1") " && \\\n"
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

	textHighlightColor = rec {
		path = [ "System Settings" "Appearance" "Theme" "Text highlight color" ];
		description = "The color used to highlight selected text. Uses the format 'R G B Name' as a space-separated string stored in AppleHighlightColor.";

		mapping =
			let
				optionName = "AppleHighlightColor";
			in
			{
				"unset" = {
					command = commandsLib.defaults.delete byHostGlobalPreferences optionName;
				};
				"Blue" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "0.031373 0.454902 0.933333 Blue";
				};
				"Purple" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "0.584314 0.239216 0.988235 Purple";
				};
				"Pink" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "1.000000 0.749020 0.823529 Pink";
				};
				"Red" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "1.000000 0.733333 0.721569 Red";
				};
				"Orange" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "1.000000 0.874510 0.701961 Orange";
				};
				"Yellow" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "1.000000 0.937255 0.690196 Yellow";
				};
				"Green" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "0.752941 0.964706 0.678431 Green";
				};
				"Graphite" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "0.847059 0.847059 0.862745 Graphite";
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

	iconAndWidgetStyle = rec {
		path = [ "System Settings" "Appearance" "Theme" "Icon & widget style" ];
		description = ''
			Controls the icon and widget appearance theme (AppleIconAppearanceTheme).

			Style options:
			  Default   — uses the current light/dark mode, no key set (unset)
			  RegularDark     — Default style, always Dark
			  RegularAutomatic — Default style, follows Auto light/dark
			  ClearLight      — Clear style, always Light
			  ClearDark       — Clear style, always Dark
			  ClearAutomatic  — Clear style, follows Auto light/dark
			  TintedLight     — Tinted style, always Light
			  TintedDark      — Tinted style, always Dark
			  TintedAutomatic — Tinted style, follows Auto light/dark
		'';

		mapping =
			let
				optionName = "AppleIconAppearanceTheme";
			in
			{
				"unset" = {
					command = commandsLib.defaults.delete byHostGlobalPreferences optionName;
				};
				"RegularDark" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "RegularDark";
				};
				"RegularAutomatic" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "RegularAutomatic";
				};
				"ClearLight" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "ClearLight";
				};
				"ClearDark" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "ClearDark";
				};
				"ClearAutomatic" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "ClearAutomatic";
				};
				"TintedLight" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "TintedLight";
				};
				"TintedDark" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "TintedDark";
				};
				"TintedAutomatic" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "TintedAutomatic";
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

	iconWidgetAndFolderColor = rec {
		path = [ "System Settings" "Appearance" "Theme" "Icon, widget & folder color" ];
		description = ''
			The tint color applied when iconAndWidgetStyle is set to a Clear or Tinted variant.
			Only relevant when AppleIconAppearanceTheme is a Clear* or Tinted* value.
			When unset (or set to "Multicolor"), the key is deleted — icons use their full color.
		'';

		mapping =
			let
				optionName = "AppleIconAppearanceTintColor";
			in
			{
				"unset" = {
					command = commandsLib.defaults.delete byHostGlobalPreferences optionName;
				};
				"Automatic" = {
					# Multicolor = no tint override; same as deleting the key
					command = commandsLib.defaults.delete byHostGlobalPreferences optionName;
				};
				"Red" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "Red";
				};
				"Orange" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "Orange";
				};
				"Yellow" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "Yellow";
				};
				"Green" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "Green";
				};
				"Blue" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "Blue";
				};
				"Purple" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "Purple";
				};
				"Pink" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "Pink";
				};
				"Graphite" = {
					command = commandsLib.defaults.write byHostGlobalPreferences optionName "string" "Graphite";
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

	sidebarIconSize = rec {
		path = [ "System Settings" "Appearance" "Windows" "Sidebar icon size" ];
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
		path = [ "System Settings" "Appearance" "Windows" "Tint window background with wallpaper color" ];
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
		path = [ "System Settings" "Appearance" "Windows" "Show scroll bars" ];
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
		path = [ "System Settings" "Appearance" "Windows" "Click in the scroll bar to" ];
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
