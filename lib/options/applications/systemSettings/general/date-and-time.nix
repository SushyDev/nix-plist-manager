{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting global system file bool text storedAs appliesThrough onlyWhen shows;

	pane = "com.apple.settings.general";
	open = [ "com.apple.systempreferences.general.dateAndTime" ];

	# systemsetup logs internal errors even when the change goes through, so only its exit status is reported.
	systemsetup = args: "/usr/sbin/systemsetup ${args} >/dev/null 2>&1 || echo ${lib.escapeShellArg "nix-plist-manager: failed: systemsetup ${args}"} >&2";
	onOff = enabled: if enabled then "on" else "off";
	option = name: "applications.systemSettings.general.dateAndTime.${name}";
in
{
	"24HourTime" = setting {
		ui = [ "System Settings" "General" "Date & Time" "24-hour time" ];
		storage = {
			force24 = global "AppleICUForce24HourTime";
			force12 = global "AppleICUForce12HourTime";
		};
		value = storedAs {
			true = { force24 = true; force12 = false; };
			false = { force24 = false; force12 = true; };
		} bool;
		verify = {
			inherit pane open;
			expect = shows.checkbox "AXCheckBox:24-hour time";
		};
	};

	# timed keeps this in /var/db/timed, readable only by root.
	setTimeAndDateAutomatically = setting {
		ui = [ "System Settings" "General" "Date & Time" "Set time and date automatically" ];
		storage = system "com.apple.timed" "TMAutomaticTimeOnlyEnabled";
		value = bool;
		canUnset = false;
		behaviors = [ (appliesThrough (enabled: systemsetup "-setusingnetworktime ${onOff enabled}")) ];
		verify = {
			inherit pane open;
			expect = shows.checkbox "AXCheckBox:Set time and date automatically";
		};
	};

	source = setting {
		ui = [ "System Settings" "General" "Date & Time" "Source" ];
		description = "The network time server, e.g. \"time.apple.com\".";
		storage = file "/etc/ntp.conf";
		value = text;
		canUnset = false;
		behaviors = [ (appliesThrough (server: systemsetup "-setnetworktimeserver ${lib.escapeShellArg server}")) ];
		reads.command = "/usr/bin/awk '/^server / { print $2; exit }' /etc/ntp.conf";
		relations = [
			(onlyWhen (option "setTimeAndDateAutomatically") (enabled: enabled)
				"the time is only fetched from a server when it's set automatically")
		];
	};

	setTimeZoneAutomaticallyUsingYourCurrentLocation = setting {
		ui = [ "System Settings" "General" "Date & Time" "Set time zone automatically using your current location" ];
		storage = system "com.apple.timezone.auto" "Active";
		value = bool;
		verify = {
			inherit pane open;
			expect = shows.checkbox "AXCheckBox:Set time zone automatically using your current location";
		};
	};

	timeZone = setting {
		ui = [ "System Settings" "General" "Date & Time" "Time zone" ];
		description = "A time zone from `systemsetup -listtimezones`, e.g. \"Europe/Amsterdam\".";
		storage = file "/etc/localtime";
		value = text;
		canUnset = false;
		behaviors = [ (appliesThrough (zone: systemsetup "-settimezone ${lib.escapeShellArg zone}")) ];
		reads.command = "/usr/bin/readlink /etc/localtime | /usr/bin/sed 's|.*/zoneinfo/||'";
		relations = [
			(onlyWhen (option "setTimeZoneAutomaticallyUsingYourCurrentLocation") (enabled: !enabled)
				"the location decides the time zone while it's set automatically")
		];
	};
}
