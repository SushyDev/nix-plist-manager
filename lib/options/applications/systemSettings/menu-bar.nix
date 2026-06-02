{ lib, commandsLib }:
let
	calculateBitmaskValue = boolOptions: bitmaskMap:
		lib.foldl' builtins.bitOr 0 (lib.mapAttrsToList (name: value:
			if builtins.isNull boolOptions.${name} then 0
			else if boolOptions.${name} or false then value 
			else 0
		) bitmaskMap);

	/**
	 * Maps the battery settings to their corresponding bitmask value.
	 *
	 * @param value An attribute set with "Show in Menu Bar" and "Show in Control Center" boolean options.
	 * @return The calculated bitmask value for the battery settings.
	 */
	mapBatteryValue = value:
		if builtins.isNull value then null
		else (if value.showInMenuBar then 0 else 8) + (if value.showInControlCenter then 1 else 0);

	mkShowActiveHideMenuBarOption = optionName: rec {
		path = [ "System Settings" "Control Center" optionName ];
		description = "";

		mapping = {
			"unset" = {
				command = commandsLib.defaults.delete "~/Library/Preferences/ByHost/com.apple.controlcenter" optionName;
			};
			"always" = {
				command = commandsLib.defaults.write "~/Library/Preferences/ByHost/com.apple.controlcenter" optionName "int" "18";
			};
			"active" = {
				command = commandsLib.defaults.write "~/Library/Preferences/ByHost/com.apple.controlcenter" optionName "int" "24";
			};
			"never" = {
				command = commandsLib.defaults.write "~/Library/Preferences/ByHost/com.apple.controlcenter" optionName "int" "24";
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
				if builtins.isNull value then null
				else mapping.${lib.escapeShellArg value}.command;
		};
	};

	mkShowHideMenuBarOption = optionName: rec {
		path = [ "System Settings" "Control Center" optionName ];
		description = "";

		mapping = {
			"unset" = {
				command = commandsLib.defaults.delete "~/Library/Preferences/ByHost/com.apple.controlcenter" optionName;
			};
			"true" = {
				command = commandsLib.defaults.write "~/Library/Preferences/ByHost/com.apple.controlcenter" optionName "int" "18";
			};
			"false" = {
				command = commandsLib.defaults.write "~/Library/Preferences/ByHost/com.apple.controlcenter" optionName "int" "24";
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

	mkBitmapOption = options: rec {
		path = [ "System Settings" "Control Center" options.name ];
		description = "";

		mapping = lib.mapAttrs (name: bitValue:
			{
				description = "System Settings > Control Center > ${options.name} > ${name}";
				command = commandsLib.defaults.write "~/Library/Preferences/ByHost/com.apple.controlcenter" options.key "int" (toString bitValue);
			}
		) options.mapping // {
			"unset" = {
				command = commandsLib.defaults.delete "~/Library/Preferences/ByHost/com.apple.controlcenter" options.key;
			};
		};

		default = null;

		option = lib.mkOption {
			inherit description default;
			type = lib.types.nullOr (lib.types.either (lib.types.enum ["unset"]) (lib.types.submodule {
				options = lib.mapAttrs (name: options: lib.mkOption {
					description = "System Settings > Control Center > ${options.name} > ${name}";
					type = lib.types.nullOr lib.types.bool;
					default = null;
				}) options.mapping;
			}));
			apply = value:
				if builtins.isNull value then null
				else if value == "unset" then "unset"
				else calculateBitmaskValue value options.mapping;
		};

		config = {
			perUser = true;
			command = value:
				if builtins.isNull value then null
				else if value == "unset" then commandsLib.defaults.delete "~/Library/Preferences/ByHost/com.apple.controlcenter" options.key
				else commandsLib.defaults.write "~/Library/Preferences/ByHost/com.apple.controlcenter" options.key "int" (toString value);
		};
	};

	showActiveHideMenuBarOptions = {
		"focusModes" = "Focus";
		"screenMirroring" = "Screen Mirroring";
		"display" = "Display";
		"sound" = "Sound";
		"nowPlaying" = "Now Playing";
	};

	showHideMenuBarOptions = {
		"wifi" = "WiFi";
		"bluetooth" = "Bluetooth";
		"airdrop" = "AirDrop";
		"stageManager" = "Stage Manager";
	};

	bitmapOptions = {
		accessibilityShortcuts = {
			name = "Accessibility Shortcuts";
			key = "AccessibilityShortcuts";
			mapping = {
				showInMenuBar = 2;
				showInControlCenter = 1;
			};
		};
		musicRecognition = {
			name = "Music Recognition";
			key = "MusicRecognition";
			mapping = {
				showInMenuBar = 2;
				showInControlCenter = 1;
			};
		};
		hearing = {
			name = "Hearing";
			key = "Hearing";
			mapping = {
				showInMenuBar = 2;
				showInControlCenter = 1;
			};
		};
		fastUserSwitching = {
			name = "User Switcher";
			key = "UserSwitcher";
			mapping = {
				showInMenuBar = 2;
				showInControlCenter = 1;
			};
		};
		keyboardBrightness = {
			name = "Keyboard Brightness";
			key = "KeyboardBrightness";
			mapping = {
				showInMenuBar = 2;
				showInControlCenter = 1;
			};
		};
	};
in
(lib.mapAttrs (name: optionName: mkShowActiveHideMenuBarOption optionName) showActiveHideMenuBarOptions) //
(lib.mapAttrs (name: optionName: mkShowHideMenuBarOption optionName) showHideMenuBarOptions) //
(lib.mapAttrs (name: options: mkBitmapOption options) bitmapOptions) //
{
	battery = rec {
		path = [ "System Settings" "Control Center" "Other Modules" "Battery" ];
		description = "";

		mapping = {
			"unset" = {
				command = commandsLib.defaults.delete "~/Library/Preferences/ByHost/com.apple.controlcenter" "Battery";
			};
			"{ showInMenuBar = true; showInControlCenter = false }" = {
				command = value: commandsLib.defaults.write "~/Library/Preferences/ByHost/com.apple.controlcenter" "Battery" "int" (mapBatteryValue { showInMenuBar = true; showInControlCenter = false; });
			};
			"{ showInMenuBar = false; showInControlCenter = true }" = {
				command = value: commandsLib.defaults.write "~/Library/Preferences/ByHost/com.apple.controlcenter" "Battery" "int" (mapBatteryValue { showInMenuBar = false; showInControlCenter = true; });
			};
			"{ showInMenuBar = true; showInControlCenter = true }" = {
				command = value: commandsLib.defaults.write "~/Library/Preferences/ByHost/com.apple.controlcenter" "Battery" "int" (mapBatteryValue { showInMenuBar = true; showInControlCenter = true; });
			};
			"{ showInMenuBar = false; showInControlCenter = false }" = {
				command = value: commandsLib.defaults.write "~/Library/Preferences/ByHost/com.apple.controlcenter" "Battery" "int" (mapBatteryValue { showInMenuBar = false; showInControlCenter = false; });
			};
		};

		default = null;

		option = lib.mkOption {
			inherit description default;
			type = lib.types.nullOr (lib.types.either (lib.types.enum [ "unset" ]) (lib.types.submodule {
				options = {
					showInMenuBar = lib.mkOption {
						description = "System Settings > Control Center > Other Modules > Battery";
						type = lib.types.nullOr lib.types.bool;
						default = null;
					};
					showInControlCenter = lib.mkOption {
						description = "System Settings > Control Center > Other Modules > Battery";
						type = lib.types.nullOr lib.types.bool;
						default = null;
					};
				};
			}));
			apply = value: if builtins.isNull value then null else mapBatteryValue value;
		};

		config = {
			perUser = true;
			command = value:
				if builtins.isNull value then null
				else if value == "unset" then commandsLib.defaults.delete "~/Library/Preferences/ByHost/com.apple.controlcenter" "Battery"
				else commandsLib.defaults.write "~/Library/Preferences/ByHost/com.apple.controlcenter" "Battery" "int" (toString value);
		};
	};
	batteryShowPercentage = rec {
		path = [ "System Settings" "Control Center" "Other Modules" "Battery" "Show Percentage" ];
		description = "";

		mapping = {
			"unset" = {
				command = commandsLib.defaults.delete "~/Library/Preferences/ByHost/com.apple.controlcenter" "BatteryShowPercentage";
			};
			"true" = {
				command = commandsLib.defaults.write "~/Library/Preferences/ByHost/com.apple.controlcenter" "BatteryShowPercentage" "bool" "true";
			};
			"false" = {
				command = commandsLib.defaults.write "~/Library/Preferences/ByHost/com.apple.controlcenter" "BatteryShowPercentage" "bool" "false";
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

	# menuBarOnly = {
	# 	spotlight = false;
	# 	siri = false;
	# };
	# automaticallyHideAndShowTheMenuBar = "In Full Screen Only";
}
