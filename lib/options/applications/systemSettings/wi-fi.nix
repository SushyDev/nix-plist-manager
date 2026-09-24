{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting system bool enum;

	pane = "com.apple.settings.wifi";
	airport = system "SystemConfiguration/com.apple.airport.preferences";

	advanced = { ui, key, control }: setting {
		ui = [ "System Settings" "Wi‑Fi" "Advanced…" ] ++ ui;
		storage = airport key;
		value = bool;
		verify = {
			inherit pane;
			open = [ "Advanced…" ];
			expect = {
				true = { "AXCheckBox:${control}" = 1; };
				false = { "AXCheckBox:${control}" = 0; };
			};
		};
	};
in
{
	askToJoinNetworks = setting {
		ui = [ "System Settings" "Wi‑Fi" "Ask to join networks" ];
		storage = airport "JoinModeFallback";
		value = enum { Off = [ "DoNothing" ]; Notify = [ "Notify" ]; Ask = [ "Prompt" ]; };
		verify = {
			inherit pane;
			expect = {
				Ask = { "AXPopUpButton:Ask to join networks" = "Ask"; };
				Notify = { "AXPopUpButton:Ask to join networks" = "Notify"; };
			};
		};
	};

	askToJoinHotspots = setting {
		ui = [ "System Settings" "Wi‑Fi" "Ask to join hotspots" ];
		storage = airport "AutoHotspotMode";
		value = enum { Never = "Never"; "Ask To Join" = "AskToJoin"; Automatic = "Automatic"; };
		verify = {
			inherit pane;
			expect = {
				Never = { "AXPopUpButton:Ask to join hotspots" = "Never"; };
				"Ask To Join" = { "AXPopUpButton:Ask to join hotspots" = "Ask To Join"; };
			};
		};
	};

	showLegacyNetworksAndOptions = advanced {
		ui = [ "Show legacy networks and options" ];
		key = "AllowLegacyNetworks";
		control = "wifi-show-legacy-networks";
	};

	requireAdministratorAuthorizationTo = {
		changeNetworks = advanced {
			ui = [ "Require administrator authorization to" "Change networks" ];
			key = "RequireAdminNetworkChange";
			control = "wifi-require-admin-network-change";
		};
		turnWiFiOnOrOff = advanced {
			ui = [ "Require administrator authorization to" "Turn Wi‑Fi on or off" ];
			key = "RequireAdminPowerToggle";
			control = "wifi-require-admin-power-toggle";
		};
	};
}
