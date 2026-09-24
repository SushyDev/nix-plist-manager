{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user byHost bool enum storedAs restarts;

	pane = "com.apple.settings.general";
	open = [ "com.apple.systempreferences.general.airDropAndHandoff" ];

	switch = { ui, storage, control, value ? bool, behaviors ? [] }: setting {
		inherit storage value behaviors;
		ui = [ "System Settings" "General" "AirDrop & Continuity" ui ];
		verify = {
			inherit pane open;
			expect = {
				true = { ${control} = 1; };
				false = { ${control} = 0; };
			};
		};
	};
in
{
	airDrop = setting {
		ui = [ "System Settings" "General" "AirDrop & Continuity" "AirDrop" ];
		storage = user "com.apple.sharingd" "DiscoverableMode";
		value = enum { "No One" = "Off"; "Contacts Only" = "Contacts Only"; Everyone = "Everyone"; };
		behaviors = [ (restarts "sharingd") ];
		verify = {
			inherit pane open;
			expect = {
				"No One" = { "AXPopUpButton:AirDrop" = "No One"; };
				"Contacts Only" = { "AXPopUpButton:AirDrop" = "Contacts Only"; };
			};
		};
	};

	allowHandoffBetweenThisMacAndYourIcloudDevices = switch {
		ui = "Allow Handoff between this Mac and your iCloud devices";
		storage = {
			advertising = byHost (user "com.apple.coreservices.useractivityd" "ActivityAdvertisingAllowed");
			receiving = byHost (user "com.apple.coreservices.useractivityd" "ActivityReceivingAllowed");
		};
		value = storedAs {
			true = { advertising = true; receiving = true; };
			false = { advertising = false; receiving = false; };
		} bool;
		control = "AXCheckBox:Allow Handoff between this Mac and your iCloud devices";
	};

	iPhoneWidgets = switch {
		ui = "iPhone Widgets";
		storage = user "com.apple.chronod" "remoteWidgetsEnabled";
		behaviors = [ (restarts "chronod") ];
		control = "use-iphone-widgets";
	};

	airPlayReceiver = switch {
		ui = "AirPlay Receiver";
		storage = byHost (user "com.apple.controlcenter" "AirplayReceiverEnabled");
		behaviors = [ (restarts "ControlCenter") ];
		control = "AXCheckBox:AirPlay Receiver";
	};
}
