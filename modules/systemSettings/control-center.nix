lib: customLib:
let
	moduleName = "Control Center";

	constants = {
		modules = {
			always = 18;
			active = 0;
			never = 24;
		};
	};

	moduleBuilder = import ../../lib/module.nix {
		moduleName = moduleName;
		constants = constants;
		inherit lib customLib;
	};

	/**
	 * Maps the battery settings to their corresponding bitmask value.
	 *
	 * @param value An attribute set with "Show in Menu Bar" and "Show in Control Center" boolean options.
	 * @return The calculated bitmask value for the battery settings.
	 */
	mapBatteryValue = value:
		if builtins.isNull value then null
		else (if value.showInMenuBar then 0 else 8) + (if value.showInControlCenter then 1 else 0);

	boolModules = 
		let
			ShowInMenuBarTrue = 18;
			ShowInMenuBarFalse = 24;
		in
		{
			wifi = {
				name = "Wi-Fi";
				onValue = ShowInMenuBarTrue;
				offValue = ShowInMenuBarFalse;
			};
			bluetooth = {
				name = "Bluetooth";
				onValue = ShowInMenuBarTrue;
				offValue = ShowInMenuBarFalse;
			};
			airdrop = {
				name = "AirDrop";
				onValue = ShowInMenuBarTrue;
				offValue = ShowInMenuBarFalse;
			};
			stageManager = {
				name = "Stage Manager";
				onValue = ShowInMenuBarTrue;
				offValue = ShowInMenuBarFalse;
			};
		};

	enumModules = {
		focusModes = "Focus";
		screenMirroring = "Screen Mirroring";
		display = "Display";
		sound = "Sound";
		nowPlaying = "Now Playing";
	};

	bitmapModules = {
		accessibilityShortcuts = {
			name = "Accessibility Shortcuts";
			mapping = {
				showInMenuBar = 2;
				showInControlCenter = 1;
			};
		};
		musicRecognition = {
			name = "Music Recognition";
			mapping = {
				showInMenuBar = 2;
				showInControlCenter = 1;
			};
		};
		hearing = {
			name = "Hearing";
			mapping = {
				showInMenuBar = 2;
				showInControlCenter = 1;
			};
		};
		fastUserSwitching = {
			name = "User Switcher";
			mapping = {
				showInMenuBar = 2;
				showInControlCenter = 1;
			};
		};
		keyboardBrightness = {
			name = "Keyboard Brightness";
			mapping = {
				showInMenuBar = 2;
				showInControlCenter = 1;
			};
		};
	};

	optionBattery = lib.mkOption {
		description = ''
			Control Center > Other Modules > Battery
			- Show in Menu Bar
			- Show in Control Center
		'';
		apply = mapBatteryValue;
		type = lib.types.nullOr (lib.types.submodule {
			options = {
				showInMenuBar = lib.mkOption {
					description = "Control Center > Other Modules > Battery";
					type = lib.types.nullOr lib.types.bool;
					default = null;
				};
				showInControlCenter = lib.mkOption {
					description = "Control Center > Other Modules > Battery";
					type = lib.types.nullOr lib.types.bool;
					default = null;
				};
			};
		});
		default = {};
	};

	optionBatteryShowPercentage = lib.mkOption {
		description = "Control Center > Other Modules > Battery > Show Percentage";
		apply = (value: if builtins.isNull value then null else if value then 1 else 0);
		type = lib.types.nullOr lib.types.bool;
		default = null;
	};
in
(lib.mapAttrs (name: displayName: moduleBuilder.mkBoolModule displayName) boolModules) //
(lib.mapAttrs (name: displayName: moduleBuilder.mkEnumModule displayName) enumModules) //
(lib.mapAttrs (name: options: moduleBuilder.mkBitmapModule options) bitmapModules) //
{
	battery = optionBattery;
	batteryShowPercentage = optionBatteryShowPercentage;
	menuBarOnly = {
		spotlight = lib.mkOption {
			description = "Control Center > Menu Bar Only > Spotlight";
			apply = (value: if builtins.isNull value then null else if value then false else true);
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
		siri = lib.mkOption {
			description = "Control Center > Menu Bar Only > Siri";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
	};
	automaticallyHideAndShowTheMenuBar = 
		let
			mapping = {
				"Always" = 1;
				"On Desktop Only" = 2;
				"In Full Screen Only" = 3;
				"Never" = 4;
			};
		in
		lib.mkOption {
			description = "Control Center > Automatically hide and show the menu bar";
			type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
			apply = (value: if builtins.isNull value then null else mapping.${value});
			default = null;
		};
}
