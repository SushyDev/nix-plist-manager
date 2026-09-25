{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting domain snapshot restarts user byHost enum shows appliesThrough conflictsWith;
	q = lib.escapeShellArg;

	store = domain "~/Library/Application Support/com.apple.wallpaper/Store/Index";

	# a picture in the flake is copied to the Nix store, under a name the store accepts
	inStore = picture:
		if lib.isPath picture then "${builtins.path { path = picture; name = "wallpaper.${lib.last (lib.splitString "." (baseNameOf picture))}"; }}"
		else picture;

	plist = body: ''<?xml version="1.0" encoding="UTF-8"?><plist version="1.0">${body}</plist>'';

	# WallpaperAgent's store: one image for every display and Space, as System Settings writes it
	setPicture = picture:
		let
			url = "file://" + lib.concatMapStringsSep "/" lib.strings.escapeURL (lib.splitString "/" (inStore picture));
			configuration = plist "<dict><key>type</key><string>imageFile</string><key>url</key><dict><key>relative</key><string>${lib.escapeXML url}</string></dict></dict>";
			options = plist "<dict><key>values</key><dict/></dict>";
			linked = "<dict><key>Type</key><string>linked</string><key>Linked</key><dict><key>Content</key><dict><key>Choices</key><array><dict><key>Provider</key><string>com.apple.wallpaper.choice.image</string><key>Files</key><array/><key>Configuration</key><data>$configuration</data></dict></array><key>EncodedOptionValues</key><data>$options</data><key>Shuffle</key><string>$null</string></dict><key>LastSet</key><date>$now</date><key>LastUse</key><date>$now</date></dict></dict>";
			index = plist "<dict><key>AllSpacesAndDisplays</key>${linked}<key>SystemDefault</key>${linked}<key>Displays</key><dict/><key>Spaces</key><dict/></dict>";
		in
		''
			work=$(/usr/bin/mktemp -d)
			printf '%s' ${q configuration} > "$work/configuration.plist"
			printf '%s' ${q options} > "$work/options.plist"
			/usr/bin/plutil -convert binary1 "$work/configuration.plist" "$work/options.plist"
			configuration=$(/usr/bin/base64 < "$work/configuration.plist")
			options=$(/usr/bin/base64 < "$work/options.plist")
			now=$(/bin/date -u +%Y-%m-%dT%H:%M:%SZ)
			printf '%s' "${lib.replaceStrings [ "\"" "$null" ] [ "\\\"" "\\$null" ] index}" > "$work/Index.plist"
			/usr/bin/plutil -convert binary1 "$work/Index.plist"
			/bin/mkdir -p "$HOME/Library/Application Support/com.apple.wallpaper/Store"
			/bin/mv "$work/Index.plist" "$HOME/Library/Application Support/com.apple.wallpaper/Store/Index.plist"
			/bin/rm -rf "$work"
		'';

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
			downloaded again after a restore. A picture of your own is only referenced by its path, so
			use `applications.systemSettings.wallpaper.picture` for that.
		'';
		storage.index = store;
		value = snapshot;
		behaviors = [ (restarts "WallpaperAgent") ];
	};

	picture = setting {
		ui = [ "System Settings" "Wallpaper" "Add Photo…" ];
		description = ''
			A picture for every display and Space, e.g. `./wallpaper.jpg` next to your configuration. It's
			copied into the Nix store, so a new Mac built from your configuration gets it too.
		'';
		storage = store;
		value = {
			kind = "picture";
			type = lib.types.either lib.types.path lib.types.str;
			choices = [];
			examples = [ "/Users/me/Pictures/wallpaper.jpg" ];
			encode = _: _: [];
			fromName = name: name;
		};
		canUnset = false;
		behaviors = [ (appliesThrough setPicture) (restarts "WallpaperAgent") ];
		relations = [
			(conflictsWith "applications.systemSettings.wallpaper.wallpaper" (_: true) "both set the wallpaper")
		];
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
