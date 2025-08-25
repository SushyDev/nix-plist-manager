lib: customLib:
{
	appearance = 
		let
			mapping = {
				"Light" = null;
				"Dark" = "Dark";
				"Auto" = "Auto";
			};
		in
		lib.mkOption {
			description = "Appearance > Appearance";
			type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
			apply = value: if builtins.isNull value then null else mapping.${value};
			default = null;
		};

	accentColor = 
		let
			mapping = {
				"Graphite" = -1;
				"Red" = 0;
				"Orange" = 1;
				"Yellow" = 2;
				"Green" = 3;
				"Blue" = 4;
				"Purple" = 5;
				"Pink" = 6;
				"Multicolor" = 7;
			};
		in
		lib.mkOption {
			description = "Appearance > Accent Color";
			type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
			apply = value: if builtins.isNull value then null else mapping.${value};
			default = null;
		};

	# TODO highlightColor

	sidebarIconSize = 
		let
			mapping = {
				"Small" = 1;
				"Medium" = 2;
				"Large" = 3;
			};
		in
		lib.mkOption {
			description = "Appearance > Sidebar icon size";
			type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
			apply = value: if builtins.isNull value then null else mapping.${value};
			default = null;
		};

	allowWallpaperTintingInWindows = lib.mkOption {
		description = "Appearance > Allow wallpaper tinting in windows";
		type = lib.types.nullOr lib.types.bool;
		apply = value: if builtins.isNull value then null else if value == true then false else true;
		default = null;
	};

	showScrollBars = 
		let
			mapping = {
				"Automatically based on mouse or trackpad" = "Automatic";
				"When scrolling" = "WhenScrolling";
				"Always" = "Always";
			};
		in
		lib.mkOption {
			description = "Appearance > Show scroll bars";
			type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
			apply = value: if builtins.isNull value then null else mapping.${value};
			default = null;
		};

	clickInTheScrollBarTo = 
		let
			mapping = {
				"Jump to the next page" = 0;
				"Jump to the spot that's clicked" = 1;
			};
		in
		lib.mkOption {
			description = "Appearance > Scroller paging behavior";
			type = lib.types.nullOr (lib.types.enum (lib.attrNames mapping));
			apply = value: if builtins.isNull value then null else mapping.${value};
			default = null;
		};
}
