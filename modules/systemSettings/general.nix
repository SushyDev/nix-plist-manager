lib: customLib:
{
	softwareUpdate = {
		automaticallyDownloadNewUpdatesWhenAvailable = lib.mkOption {
			description = "System > Software Update > Download new updates when available";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
		automaticallyInstallMacOSUpdates = lib.mkOption {
			description = "System > Software Update > Install macOS updates";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
		automaticallyInstallApplicationUpdatesFromTheAppStore = lib.mkOption {
			description = "System > Software Update > Install application updates from the App Store";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
		automaticallyInstallSecurityResponseAndSystemFiles = lib.mkOption {
			description = "System > Software Update > Install Security Response and system files";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
	};
	dateAndTime = {
		setTimeAndDateAutomatically = lib.mkOption {
			description = "System > Date & Time > Set time and date automatically";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
		# source =
		# dateAndTime =
		"24HourTime" = lib.mkOption {
			description = "System > Date & Time > 24-hour time";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
		show24HourTimeOnLockScreen = lib.mkOption {
			description = "System > Date & Time > Show 24-hour time on lock screen";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
		setTimeZoneAutomaticallyUsingCurrentLocation = lib.mkOption {
			description = "System > Date & Time > Set time zone automatically using current location";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
		# timeZone =
		# closestCity =
	};
}
