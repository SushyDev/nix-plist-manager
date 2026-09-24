{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting domain snapshot restarts user byHost enum shows;

	screenSaverDelays = {
		"After 1 minute" = 60; "After 2 minutes" = 120; "After 3 minutes" = 180; "After 5 minutes" = 300;
		"After 10 minutes" = 600; "After 20 minutes" = 1200; "After 30 minutes" = 1800; "After 1 hour" = 3600;
		"After 1 hour, 30 minutes" = 5400; "After 2 hours" = 7200; "After 2 hours, 30 minutes" = 9000;
		"After 3 hours" = 10800; Never = 0;
	};
in
{
	wallpaper = setting {
		ui = [ "System Settings" "Wallpaper" ];
		description = ''
			The wallpaper as picked in System Settings, for every display and Space. Save it into your
			configuration with
			`nix run github:sushydev/nix-plist-manager#capture -- applications.systemSettings.wallpaper.wallpaper <directory>`
			and set this option to that directory. Wallpapers that are downloaded on demand are
			downloaded again after a restore.
		'';
		storage.index = domain "~/Library/Application Support/com.apple.wallpaper/Store/Index";
		value = snapshot;
		behaviors = [ (restarts "WallpaperAgent") ];
	};

	startScreenSaver = setting {
		ui = [ "System Settings" "Wallpaper" "Screen Saver…" "Start Screen Saver…" ];
		storage = byHost (user "com.apple.screensaver" "idleTime");
		value = enum screenSaverDelays;
		verify = {
			pane = "com.apple.settings.wallpaper";
			open = [ "AXButton:Screen Saver…" ];
			expect = shows.choice "AXPopUpButton:Start Screen Saver…" [ "After 5 minutes" "Never" ];
		};
	};
}
