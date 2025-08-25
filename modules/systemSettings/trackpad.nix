lib: customLib:
{
	trackingSpeed = 
		let
			mapping = {
				"1" = 0;
				"2" = 0.125;
				"3" = 0.5;
				"4" = 0.6875;
				"5" = 0.873;
				"6" = 1;
				"7" = 1.5;
				"8" = 2;
				"9" = 2.5;
				"10" = 3;
			};
		in
		lib.mkOption {
			description = "Trackpad > Tracking speed";
			type = lib.types.nullOr (lib.types.ints.between 1 10);
			apply = value: if builtins.isNull value then null else mapping.${toString value};
			default = null;
		};

	click =
		let
			mapping = {
				"Light" = 0;
				"Medium" = 1;
				"Firm" = 2;
			};
		in
		lib.mkOption {
			description = "Trackpad > Click";
			type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
			apply = value: if builtins.isNull value then null else mapping.${value};
			default = null;
		};

	forceClickAndHapticFeedback = lib.mkOption {
		description = "Trackpad > Force Click and haptic feedback";
		type = lib.types.nullOr lib.types.bool;
		default = null;
	};

	# TODO lookUpAndDataDetectors
	# TODO secondaryClick

	tapToClick = lib.mkOption {
		description = "Trackpad > Tap to click";
		type = lib.types.nullOr lib.types.bool;
		default = null;
	};
}
