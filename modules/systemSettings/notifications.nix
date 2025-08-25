lib: customLib:
{
	notificationCenter = {
		showPreviews = 
			let
				mapping = {
					"always" = 3;
					"whenUnlocked" = 2;
					"never" = 1;
				};
			in
			lib.mkOption {
				description = "Notification Center > Show Previews";
				type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
				apply = value: if builtins.isNull value then null else mapping.${value};
				default = null;
			};

		summarizeNotifications = lib.mkOption {
			description = "Notification Center > Summarize Notifications";
			type = lib.types.nullOr lib.types.bool;
			default = null;
		};
	};
}
