{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user bool inverted restarts shows;
in
{
	shareAcrossDevices = setting {
		ui = [ "System Settings" "Focus" "Share across devices" ];
		storage = user "com.apple.donotdisturbd" "disableCloudSync";
		value = inverted bool;
		behaviors = [ (restarts "donotdisturbd") ];
		verify = {
			pane = "com.apple.settings.focus";
			expect = shows.checkbox "AXCheckBox:Share across devices";
		};
	};
}
