{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting system bool enum shows;

	pane = "com.apple.settings.wifi";
	airport = system "SystemConfiguration/com.apple.airport.preferences";

	advanced = { ui, key, control }: setting {
		ui = [ "System Settings" "Wi‑Fi" "Advanced…" ] ++ ui;
		storage = airport key;
		value = bool;
		verify = {
			inherit pane;
			open = [ "Advanced…" ];
			expect = shows.checkbox "AXCheckBox:${control}";
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
			expect = shows.choice "AXPopUpButton:Ask to join networks" [ "Ask" "Notify" ];
		};
	};

	askToJoinHotspots = setting {
		ui = [ "System Settings" "Wi‑Fi" "Ask to join hotspots" ];
		storage = airport "AutoHotspotMode";
		value = enum { Never = "Never"; "Ask To Join" = "AskToJoin"; Automatic = "Automatic"; };
		verify = {
			inherit pane;
			expect = shows.choice "AXPopUpButton:Ask to join hotspots" [ "Never" "Ask To Join" ];
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
