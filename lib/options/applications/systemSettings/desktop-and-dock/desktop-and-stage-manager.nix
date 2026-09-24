{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user bool inverted enum shows;

	pane = "com.apple.settings.desktopAndDock";
	windowManager = name: user "com.apple.WindowManager" name;

	switch = { ui, key, control, value ? bool, operate ? true }: setting {
		inherit ui value;
		storage = windowManager key;
		verify = {
			inherit pane;
			expect = shows.checkbox control;
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
			expect = shows.choice "click-wallpaper-to-reveal-desktop" [ "Always" "Only in Stage Manager" ];
		};
	};

	stageManager = switch {
		ui = [ "System Settings" "Desktop & Dock" "Desktop & Stage Manager" "Stage Manager" ];
		key = "GloballyEnabled";
		control = "stage-manager-on";
		# Turning it on in System Settings asks for confirmation in a separate dialog first.
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
			expect = shows.choice "show-windows-from-application" [ "All at Once" "One at a Time" ];
		};
	};
}
