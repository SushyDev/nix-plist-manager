{ lib, settingsLib, ... }:
# Each network service's configuration (addresses, DNS, proxies, VPN) is kept in
# SystemConfiguration's preferences and belongs to nix-darwin's networking options, so only the
# firewall is here. The application firewall keeps its own state and is changed through
# socketfilterfw, as root.
let
	inherit (settingsLib) setting file bool appliesThrough;

	socketfilterfw = "/usr/libexec/ApplicationFirewall/socketfilterfw";

	# `readFlag`: the --get flag that reports it, when it isn't named like the --set flag
	firewall = { ui, flag, readFlag ? flag }: setting {
		ui = [ "System Settings" "Network" "Firewall" ] ++ ui;
		storage = file "${socketfilterfw} --get${readFlag}";
		value = bool;
		canUnset = false;
		behaviors = [ (appliesThrough (on: "${socketfilterfw} --set${flag} ${if on then "on" else "off"} >/dev/null")) ];
	};
in
{
	firewall = {
		firewall = firewall { ui = [ "Firewall" ]; flag = "globalstate"; };

		options = {
			blockAllIncomingConnections = firewall { ui = [ "Options…" "Block all incoming connections" ]; flag = "blockall"; };
			automaticallyAllowBuiltInSoftwareToReceiveIncomingConnections = firewall {
				ui = [ "Options…" "Automatically allow built-in software to receive incoming connections" ];
				flag = "allowsigned";
			};
			automaticallyAllowDownloadedSignedSoftwareToReceiveIncomingConnections = firewall {
				ui = [ "Options…" "Automatically allow downloaded signed software to receive incoming connections" ];
				flag = "allowsignedapp";
				readFlag = "allowsigned";
			};
			enableStealthMode = firewall { ui = [ "Options…" "Enable stealth mode" ]; flag = "stealthmode"; };
		};
	};
}
