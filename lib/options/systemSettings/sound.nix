{ lib, commandsLib, pathLib, typesLib, configLib, abstractionsLib }:
let
	globalPreferences = pathLib.generatePath true false ".GlobalPreferences";
in
{
	soundEffects = {
		alertSound = abstractionsLib.mkBasicMappingOption {
			description = "System Settings > Sound > Sound Effects > Alert sound";
			default = null;
			perUser = true;
			mapping = 
				let
					optionName = "com.apple.sound.beep.sound";
				in
				{
					"unset" = {
						command = commandsLib.defaults.delete globalPreferences optionName;
					};
					"Boop" = {
						command = commandsLib.defaults.write globalPreferences optionName "string" "/System/Library/Sounds/Tink.aiff";
					};
					"Breeze" = {
						command = commandsLib.defaults.write globalPreferences optionName "string" "/System/Library/Sounds/Blow.aiff";
					};
					"Bubble" = {
						command = commandsLib.defaults.write globalPreferences optionName "string" "/System/Library/Sounds/Pop.aiff";
					};
					"Crystal" = {
						command = commandsLib.defaults.write globalPreferences optionName "string" "/System/Library/Sounds/Glass.aiff";
					};
					"Funky" = {
						command = commandsLib.defaults.write globalPreferences optionName "string" "/System/Library/Sounds/Funk.aiff";
					};
					"Heroine" = {
						command = commandsLib.defaults.write globalPreferences optionName "string" "/System/Library/Sounds/Hero.aiff";
					};
					"Jump" = {
						command = commandsLib.defaults.write globalPreferences optionName "string" "/System/Library/Sounds/Frog.aiff";
					};
					"Mezzo" = {
						command = commandsLib.defaults.write globalPreferences optionName "string" "/System/Library/Sounds/Basso.aiff";
					};
					"Pebble" = {
						command = commandsLib.defaults.write globalPreferences optionName "string" "/System/Library/Sounds/Bottle.aiff";
					};
					"Pluck" = {
						command = commandsLib.defaults.write globalPreferences optionName "string" "/System/Library/Sounds/Purr.aiff";
					};
					"Pong" = {
						command = commandsLib.defaults.write globalPreferences optionName "string" "/System/Library/Sounds/Morse.aiff";
					};
					"Sonar" = {
						command = commandsLib.defaults.write globalPreferences optionName "string" "/System/Library/Sounds/Ping.aiff";
					};
					"Sonumi" = {
						command = commandsLib.defaults.write globalPreferences optionName "string" "/System/Library/Sounds/Sosumi.aiff";
					};
					"Submerge" = {
						command = commandsLib.defaults.write globalPreferences optionName "string" "/System/Library/Sounds/Submarine.aiff";
					};
				};
		};
		alertVolume = rec {
			description = "Notifications > Summarize Notifications";

			mapping = 
				let
					optionName = "com.apple.sound.beep.volume";
				in
				{
					"unset" = {
						command = commandsLib.defaults.delete globalPreferences optionName;
					};
					"value" = {
						command = value: commandsLib.defaults.write globalPreferences optionName "float" (toString value);
					};
				};

			default = null;

			option = lib.mkOption {
				inherit description default;
				type =
					let
						minValue = 0.0;
						maxValue = 1.0;
					in
					typesLib.nullOrFloatsBetweenOrUnset minValue maxValue;
			};

			config = {
				perUser = true;
				command = configLib.commandNullOrValueOrUnset mapping;
			};
		};
		playUserInterfaceSoundEffects = 
			let
				optionName = "com.apple.sound.uiaudio.enabled";
			in
			abstractionsLib.mkBasicBoolOption {
				description = "System Settings > Sound > Sound Effects > Play user interface sound effects";
				default = null;
				perUser = true;
				unsetCommand = commandsLib.defaults.delete globalPreferences optionName;
				trueCommand = commandsLib.defaults.write globalPreferences optionName "bool" "true";
				falseCommand = commandsLib.defaults.write globalPreferences optionName "bool" "false";
			};
		playFeedbackWhenVolumeIsChanged = 
			let
				optionName = "com.apple.sound.beep.feedback";
			in
			abstractionsLib.mkBasicBoolOption {
				description = "System Settings > Sound > Sound Effects > Play feedback when volume is changed";
				default = null;
				perUser = true;
				unsetCommand = commandsLib.defaults.delete globalPreferences optionName;
				trueCommand = commandsLib.defaults.write globalPreferences optionName "bool" "true";
				falseCommand = commandsLib.defaults.write globalPreferences optionName "bool" "false";
			};
	};
}
