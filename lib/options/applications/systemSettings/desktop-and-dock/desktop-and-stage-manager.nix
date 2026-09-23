{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user bool inverted enum;

	pane = "com.apple.settings.desktopAndDock";
	windowManager = name: user "com.apple.WindowManager" name;

	# a WindowManager switch, many of which store the opposite ("hide …")
	switch = { ui, key, control, value ? bool, operate ? true }: setting {
		inherit ui value;
		storage = windowManager key;
		verify = {
			inherit pane;
			expect = {
				true = { ${control} = 1; };
				false = { ${control} = 0; };
			};
		} // lib.optionalAttrs operate { operate = [ "click" control ]; };
	};
in
{
	showItems = {
		onDesktop = switch {
			ui = [ "System Settings" "Desktop & Dock" "Desktop & Stage Manager" "Show items" "On Desktop" ];
			key = "StandardHideDesktopIcons";
			value = inverted bool;
			control = "show-items-on-desktop";
		};
		inStageManager = switch {
			ui = [ "System Settings" "Desktop & Dock" "Desktop & Stage Manager" "Show items" "In Stage Manager" ];
			key = "HideDesktop";
			value = inverted bool;
			control = "show-items-in-stage-manager";
		};
	};

	clickWallpaperToRevealDesktop = setting {
		ui = [ "System Settings" "Desktop & Dock" "Desktop & Stage Manager" "Click wallpaper to show desktop" ];
		storage = windowManager "EnableStandardClickToShowDesktop";
		value = enum { Always = true; "Only in Stage Manager" = false; };
		verify = {
			inherit pane;
			expect = {
				Always = { click-wallpaper-to-reveal-desktop = "Always"; };
				"Only in Stage Manager" = { click-wallpaper-to-reveal-desktop = "Only in Stage Manager"; };
			};
		};
	};

	stageManager = switch {
		ui = [ "System Settings" "Desktop & Dock" "Desktop & Stage Manager" "Stage Manager" ];
		key = "GloballyEnabled";
		control = "stage-manager-on";
		# turning it on in System Settings asks for confirmation in a separate dialog first
		operate = false;
	};

	showRecentAppsInStageManager = switch {
		ui = [ "System Settings" "Desktop & Dock" "Desktop & Stage Manager" "Show recent apps in Stage Manager" ];
		key = "AutoHide";
		value = inverted bool;
		control = "recent-applications";
	};

	showWindowsFromAnApplication = setting {
		ui = [ "System Settings" "Desktop & Dock" "Desktop & Stage Manager" "Show windows from an application" ];
		storage = windowManager "AppWindowGroupingBehavior";
		value = enum { "All at Once" = 1; "One at a Time" = 0; };
		verify = {
			inherit pane;
			expect = {
				"All at Once" = { show-windows-from-application = "All at Once"; };
				"One at a Time" = { show-windows-from-application = "One at a Time"; };
			};
		};
	};
}
