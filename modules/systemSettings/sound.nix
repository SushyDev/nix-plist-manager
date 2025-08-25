lib: customLib:
{
	soundEffects = {
		alertSound = 
			let
				mapping = {
					"Boop" = "/System/Library/Sounds/Tink.aiff";
					"Breeze" = "/System/Library/Sounds/Blow.aiff";
					"Bubble" = "/System/Library/Sounds/Pop.aiff";
					"Crystal" = "/System/Library/Sounds/Glass.aiff";
					"Funky" = "/System/Library/Sounds/Funk.aiff";
					"Heroine" = "/System/Library/Sounds/Hero.aiff";
					"Jump" = "/System/Library/Sounds/Frog.aiff";
					"Mezzo" = "/System/Library/Sounds/Basso.aiff";
					"Pebble" = "/System/Library/Sounds/Bottle.aiff";
					"Pluck" = "/System/Library/Sounds/Purr.aiff";
					"Pong" = "/System/Library/Sounds/Morse.aiff";
					"Sonar" = "/System/Library/Sounds/Ping.aiff";
					"Sonumi" = "/System/Library/Sounds/Sosumi.aiff";
					"Submerge" = "/System/Library/Sounds/Submarine.aiff";

				};
			in
			lib.mkOption {
				description = "Sound > Sound Effects > Alert sound";
				type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
				apply = value: if builtins.isNull value then null else mapping.${value};
				default = null;
			};

		alertVolume = lib.mkOption {
			description = "Sound > Sound Effects > Alert volume";
			type = lib.types.nullOr (customLib.types.floatBetween 0.0 1.0);
			default = null;
		};
		# TODO playSoundOnStartup = Needs NVRAM impl.
		playUserInterfaceSoundEffects = lib.mkOption {
			description = "Sound > Sound Effects > Play user interface sound effects";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
		playFeedbackWhenVolumeIsChanged = lib.mkOption {
			description = "Sound > Sound Effects > Play feedback when volume is changed";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
	};
}
