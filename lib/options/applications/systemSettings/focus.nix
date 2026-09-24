{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user bool inverted restarts;
in
{
	shareAcrossDevices = setting {
		ui = [ "System Settings" "Focus" "Share across devices" ];
		storage = user "com.apple.donotdisturbd" "disableCloudSync";
		value = inverted bool;
		behaviors = [ (restarts "donotdisturbd") ];
		verify = {
			pane = "com.apple.settings.focus";
			expect = {
				true = { "AXCheckBox:Share across devices" = 1; };
				false = { "AXCheckBox:Share across devices" = 0; };
			};
		};
	};
}
