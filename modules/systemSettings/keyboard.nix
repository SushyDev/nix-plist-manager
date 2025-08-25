lib: customLib:
{
	keyRepeatRate = 
		let
			mapping = {
				"1" = 120;
				"2" = 90;
				"3" = 60;
				"4" = 30;
				"5" = 12;
				"6" = 5;
				"7" = 2;
			};
		in
		lib.mkOption {
			description = "Focus > Share across devices";
			type = lib.types.nullOr (lib.types.ints.between 1 7);
			apply = value: if builtins.isNull value then null else mapping.${toString value};
			default = null;
		};

	keyRepeatDelay = 
		let
			mapping = {
				"1" = 120;
				"2" = 94;
				"3" = 68;
				"4" = 30;
				"5" = 25;
				"6" = 15;
			};
		in
		lib.mkOption {
			description = "Focus > Share across devices";
			type = lib.types.nullOr (lib.types.ints.between 1 6);
			apply = value: if builtins.isNull value then null else mapping.${toString value};
			default = null;
		};

	adjustKeyboardBrightnessInLowLight = lib.mkOption {
		description = "Keyboard > Adjust keyboard brightness in low light";
		type = lib.types.nullOr lib.types.bool;
		default = null;
	};

	keyboardBrightness = lib.mkOption {
		description = "Keyboard > Keyboard brightness";
		type = lib.types.nullOr (customLib.types.floatBetween 0.0 1.0);
		default = null;
	};

	turnKeyboardBacklightOffAfterInactivity =
		let
			mapping = {
				"After 5 Seconds" = 5;
				"After 10 Seconds" = 10;
				"After 30 Seconds" = 30;
				"After 1 Minute" = 60;
				"After 5 Minutes" = 300;
				"Never" = 0;
			};
		in
		lib.mkOption {
			description = "Keyboard > Turn keyboard backlight off after inactivity";
			type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
			apply = value: if builtins.isNull value then null else mapping.${value};
			default = null;
		};

	pressGlobeKeyTo =
		let
			mapping = {
				"Change Input Source" = 1;
				"Show Emoji & Symbols" = 2;
				"Start Dictation (Press Globe Key Twice)" = 3;
				"Do Nothing" = 0;
			};
		in
		lib.mkOption {
			description = "Keyboard > Press Globe key to";
			type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
			apply = value: if builtins.isNull value then null else mapping.${value};
			default = null;
		};

	keyboardNavigation = lib.mkOption {
		description = "Keyboard > Keyboard navigation";
		type = lib.types.nullOr lib.types.bool;
		apply = value: if builtins.isNull value then null else if value then 2 else 0;
		default = null;
	};

	keyboardShortcuts = {
		# TODO Lots of work to be done here
		functionKeys = {
			useF1F2EtcAsStandardFunctionKeys = lib.mkOption {
				description = "Keyboard Shortcuts > Use F1, F2, etc. keys as standard function keys";
				type = lib.types.nullOr lib.types.bool;
				default = null;
			};
		};
	};

	dictation = {
		enabled = lib.mkOption {
			description = "Dictation";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
		# TODO shortcut =
		# TODO autoPunctuation =
	};
}
