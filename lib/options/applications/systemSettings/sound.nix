{ lib, settingsLib, ... }:
# Output and input devices, volume, mute and balance change with what's connected and aren't
# covered.
let
	inherit (settingsLib) setting global file bool enum number storedAs appliesThrough;

	pane = "com.apple.settings.sounds";

	switch = { ui, storage, control, value ? storedAs { true = 1; false = 0; } bool }: setting {
		inherit storage value;
		ui = [ "System Settings" "Sound" ui ];
		verify = {
			inherit pane;
			expect = {
				true = { "AXCheckBox:${control}" = 1; };
				false = { "AXCheckBox:${control}" = 0; };
			};
		};
	};
in
{
	soundEffects = {
		alertSound = setting {
			ui = [ "System Settings" "Sound" "Alert sound" ];
			storage = global "com.apple.sound.beep.sound";
			value = enum (lib.mapAttrs (_: file: "/System/Library/Sounds/${file}.aiff") {
				Boop = "Tink"; Breeze = "Blow"; Bubble = "Pop"; Crystal = "Glass"; Funky = "Funk"; Heroine = "Hero";
				Jump = "Frog"; Mezzo = "Basso"; Pebble = "Bottle"; Pluck = "Purr"; Pong = "Morse"; Sonar = "Ping";
				Sonumi = "Sosumi"; Submerge = "Submarine";
			});
			verify = {
				inherit pane;
				expect = {
					Sonar = { "AXPopUpButton:AlertSoundPicker" = "Sonar"; };
					Boop = { "AXPopUpButton:AlertSoundPicker" = "Boop"; };
				};
			};
		};

		alertVolume = setting {
			ui = [ "System Settings" "Sound" "Alert volume" ];
			storage = global "com.apple.sound.beep.volume";
			value = number { min = 0.0; max = 1.0; };
		};

		# a firmware variable, set as root
		playSoundOnStartup = setting {
			ui = [ "System Settings" "Sound" "Play sound on startup" ];
			storage = file "nvram StartupMute";
			value = bool;
			canUnset = false;
			behaviors = [ (appliesThrough (play: "/usr/sbin/nvram StartupMute=${if play then "%00" else "%01"}")) ];
			verify = {
				inherit pane;
				expect = {
					true = { "AXCheckBox:BootChimeCheckbox" = 1; };
					false = { "AXCheckBox:BootChimeCheckbox" = 0; };
				};
			};
		};

		# the key System Settings writes, but its switch doesn't follow it (and ignores clicks on
		# this Mac), so this isn't verified
		playUserInterfaceSoundEffects = switch {
			ui = "Play user interface sound effects";
			storage = global "com.apple.sound.uiaudio.enabled";
			control = "SoundEffectsCheckbox";
		} // { verify = null; };

		playFeedbackWhenVolumeIsChanged = switch {
			ui = "Play feedback when volume is changed";
			storage = global "com.apple.sound.beep.feedback";
			control = "VolumeKeyFeedbackCheckbox";
		};
	};
}
