{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting global stored absent bool inverted number enum notifies appliesThrough live
		allowedWhen onlyWhen;

	pane = "com.apple.settings.appearance";
	option = name: "applications.systemSettings.appearance.${name}";

	colorsChanged = notifies [ "AppleColorPreferencesChangedNotification" "AppleAquaColorVariantChanged" ];

	selected = { selected = true; };
in
{
	appearance = setting {
		ui = [ "System Settings" "Appearance" "Appearance" ];
		storage = {
			style = global "AppleInterfaceStyle";
			automatic = global "AppleInterfaceStyleSwitchesAutomatically";
		};
		value = enum {
			Light = { style = absent; automatic = absent; };
			Dark = { style = "Dark"; automatic = absent; };
			Auto = { automatic = true; };
		};
		behaviors = [
			(appliesThrough (value:
				if value == "Auto" then live.appearance.automatic true
				else [ (live.appearance.automatic false) (live.appearance.dark (value == "Dark")) ]
			))
		];
		verify = {
			inherit pane;
			expect = {
				Light = { "AXButton:Light" = selected; };
				Dark = { "AXButton:Dark" = selected; };
				Auto = { "AXButton:Auto" = selected; };
			};
		};
	};

	liquidGlass = setting {
		ui = [ "System Settings" "Appearance" "Liquid Glass" ];
		description = "How tinted Liquid Glass is, from 0 (clear) to 1 (tinted). System Settings defaults to 0.5.";
		storage = stored "float" (global "NSGlassTintAmount");
		value = number { min = 0.0; max = 1.0; };
		verify = {
			inherit pane;
			expect = {
				"0" = { "Liquid Glass Tint Amount" = 0; };
				"0.5" = { "Liquid Glass Tint Amount" = 0.5; };
				"1" = { "Liquid Glass Tint Amount" = 1; };
			};
		};
	};

	accentColor = setting {
		ui = [ "System Settings" "Appearance" "Theme" "Color" ];
		storage = {
			color = global "AppleAccentColor";
			variant = global "AppleAquaColorVariant";
		};
		value = enum {
			Multicolor = { color = absent; variant = 1; };
			Graphite = { color = -1; variant = 6; };
			Red = { color = 0; variant = 1; };
			Orange = { color = 1; variant = 1; };
			Yellow = { color = 2; variant = 1; };
			Green = { color = 3; variant = 1; };
			Blue = { color = 4; variant = 1; };
			Purple = { color = 5; variant = 1; };
			Pink = { color = 6; variant = 1; };
		};
		behaviors = [ colorsChanged ];
		verify = {
			inherit pane;
			expect = {
				Blue = { "AXStaticText:Color" = "Blue"; };
				Multicolor = { "AXStaticText:Color" = "Multicolor"; };
				Graphite = { "AXStaticText:Color" = "Graphite"; };
			};
		};
	};

	textHighlightColor = setting {
		ui = [ "System Settings" "Appearance" "Theme" "Text highlight color" ];
		description = "The color of selected text. Automatic follows the accent color.";
		storage = global "AppleHighlightColor";
		value = enum {
			Automatic = absent;
			Blue = "0.698039 0.843137 1.000000 Blue";
			Purple = "0.968627 0.831373 1.000000 Purple";
			Pink = "1.000000 0.749020 0.823529 Pink";
			Red = "1.000000 0.733333 0.721569 Red";
			Orange = "1.000000 0.874510 0.701961 Orange";
			Yellow = "1.000000 0.937255 0.690196 Yellow";
			Green = "0.752941 0.964706 0.678431 Green";
			Graphite = "0.847059 0.847059 0.862745 Graphite";
		};
		behaviors = [ colorsChanged ];
		relations = [
			(allowedWhen "Automatic" (option "accentColor") (color: color == "Multicolor")
				"System Settings only offers Automatic with the Multicolor accent color")
		];
		verify = {
			inherit pane;
			expect = {
				Purple = { HighlightColorPicker = "Purple"; };
				Blue = { HighlightColorPicker = "Blue"; };
			};
		};
	};

	iconAndWidgetStyle = setting {
		ui = [ "System Settings" "Appearance" "Theme" "Icon & widget style" ];
		description = "The icon and widget style, and whether it's light, dark or automatic. \"unset\" is Default in Light.";
		storage = global "AppleIconAppearanceTheme";
		value = enum {
			RegularDark = "RegularDark";
			RegularAutomatic = "RegularAutomatic";
			ClearLight = "ClearLight";
			ClearDark = "ClearDark";
			ClearAutomatic = "ClearAutomatic";
			TintedLight = "TintedLight";
			TintedDark = "TintedDark";
			TintedAutomatic = "TintedAutomatic";
		};
		verify = {
			inherit pane;
			expect = {
				ClearDark = { "Clear + Icon & widget style" = selected; "AXRadioButton:Dark" = 1; };
				# The Default style shows as Dark in dark or automatic appearance.
				RegularAutomatic = { "Dark + Icon & widget style" = selected; "AXRadioButton:Auto" = 1; };
				TintedLight = { "Tinted + Icon & widget style" = selected; "AXRadioButton:Light" = 1; };
			};
		};
	};

	iconWidgetAndFolderColor = setting {
		ui = [ "System Settings" "Appearance" "Theme" "Icon, widget & folder color" ];
		storage = global "AppleIconAppearanceTintColor";
		value = enum {
			Automatic = absent;
			Red = "Red";
			Orange = "Orange";
			Yellow = "Yellow";
			Green = "Green";
			Blue = "Blue";
			Purple = "Purple";
			Pink = "Pink";
			Graphite = "Graphite";
		};
		relations = [
			(onlyWhen (option "iconAndWidgetStyle")
				(style: lib.any (prefix: lib.hasPrefix prefix style) [ "Clear" "Tinted" ])
				"only the Clear and Tinted styles use it")
		];
		verify = {
			inherit pane;
			expect = {
				Red = { "Icon, widget & Folder color" = "Red"; };
				Graphite = { "Icon, widget & Folder color" = "Graphite"; };
			};
		};
	};

	sidebarIconSize = setting {
		ui = [ "System Settings" "Appearance" "Windows" "Sidebar icon size" ];
		storage = global "NSTableViewDefaultSizeMode";
		value = enum { Small = 1; Medium = 2; Large = 3; };
		verify = {
			inherit pane;
			expect = {
				Small = { SidebarIconSizePicker = "Small"; };
				Medium = { SidebarIconSizePicker = "Medium"; };
				Large = { SidebarIconSizePicker = "Large"; };
			};
		};
	};

	allowWallpaperTintingInWindows = setting {
		ui = [ "System Settings" "Appearance" "Windows" "Tint window background with wallpaper color" ];
		storage = global "AppleReduceDesktopTinting";
		value = inverted bool;
		verify = {
			inherit pane;
			operate = [ "click" "TintWindowBackgroundToggle" ];
			expect = {
				true = { TintWindowBackgroundToggle = 1; };
				false = { TintWindowBackgroundToggle = 0; };
			};
		};
	};

	showScrollBars = setting {
		ui = [ "System Settings" "Appearance" "Windows" "Show scroll bars" ];
		storage = global "AppleShowScrollBars";
		value = enum {
			"Automatically based on mouse or trackpad" = "Automatic";
			"When scrolling" = "WhenScrolling";
			"Always" = "Always";
		};
		verify = {
			inherit pane;
			expect = {
				"Always" = { "AXRadioButton:Always" = 1; };
				"When scrolling" = { "AXRadioButton:When scrolling" = 1; };
				"Automatically based on mouse or trackpad" = { "AXRadioButton:Automatically based on mouse or trackpad" = 1; };
			};
		};
	};

	clickInTheScrollBarTo = setting {
		ui = [ "System Settings" "Appearance" "Windows" "Click in the scroll bar to" ];
		storage = global "AppleScrollerPagingBehavior";
		value = enum {
			"Jump to the next page" = false;
			"Jump to the spot that's clicked" = true;
		};
		verify = {
			inherit pane;
			operate = [ [ "press" "AXRadioButton:Jump to the spot that’s clicked" ] [ "press" "AXRadioButton:Jump to the next page" ] ];
			expect = {
				"Jump to the next page" = { "AXRadioButton:Jump to the next page" = 1; };
				"Jump to the spot that's clicked" = { "AXRadioButton:Jump to the spot that’s clicked" = 1; };
			};
		};
	};
}
