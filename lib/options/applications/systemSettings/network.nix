{ lib, settingsLib, ... }:
# Each network service's configuration (addresses, DNS, proxies, VPN) is kept in
# SystemConfiguration's preferences and belongs to nix-darwin's networking options, so only the
# firewall is here. The application firewall keeps its own state and is changed through
# socketfilterfw, as root.
let
	inherit (settingsLib) setting file bool appliesThrough;

	socketfilterfw = "/usr/libexec/ApplicationFirewall/socketfilterfw";

	# `readFlag`: the --get flag that reports it, when it isn't named like the --set flag; `on`:
	# what that prints while it's on
	firewall = { ui, flag, readFlag ? flag, on }: setting {
		ui = [ "System Settings" "Network" "Firewall" ] ++ ui;
		storage = file "${socketfilterfw} --get${readFlag}";
		value = bool;
		canUnset = false;
		behaviors = [ (appliesThrough (on: "${socketfilterfw} --set${flag} ${if on then "on" else "off"} >/dev/null")) ];
		reads.command = "${socketfilterfw} --get${readFlag} | /usr/bin/grep -qi ${lib.escapeShellArg on} && echo true || echo false";
	};
in
{
	firewall = {
		firewall = firewall { ui = [ "Firewall" ]; flag = "globalstate"; on = "is enabled"; };

		options = {
			blockAllIncomingConnections = firewall { ui = [ "Options…" "Block all incoming connections" ]; flag = "blockall"; on = "set to enabled"; };
			automaticallyAllowBuiltInSoftwareToReceiveIncomingConnections = firewall {
				ui = [ "Options…" "Automatically allow built-in software to receive incoming connections" ];
				flag = "allowsigned";
				on = "built-in signed software enabled";
			};
			automaticallyAllowDownloadedSignedSoftwareToReceiveIncomingConnections = firewall {
				ui = [ "Options…" "Automatically allow downloaded signed software to receive incoming connections" ];
				flag = "allowsignedapp";
				readFlag = "allowsigned";
				on = "downloaded signed software enabled";
			};
			enableStealthMode = firewall { ui = [ "Options…" "Enable stealth mode" ]; flag = "stealthmode"; on = "stealth mode is on"; };
		};
	};
}
