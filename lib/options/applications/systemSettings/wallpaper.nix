{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting domain snapshot restarts user byHost enum shows appliesThrough conflictsWith;
	q = lib.escapeShellArg;

	store = domain "~/Library/Application Support/com.apple.wallpaper/Store/Index";
	catalog = lib.importJSON ./wallpapers.json;

	picker = id: { picker._0 = { inherit id; }; };
	toggle = on: { toggle._0.isOn = on; };
	fileURL = path: "file://" + lib.concatMapStringsSep "/" lib.strings.escapeURL (lib.splitString "/" path);
	plist = lib.generators.toPlist { escape = true; };

	# a file in the flake is copied to the Nix store, under a name the store accepts
	inStore = path:
		if lib.isPath path then "${builtins.path { inherit path; name = "wallpaper${lib.optionalString (lib.pathIsRegularFile path) ".${lib.last (lib.splitString "." (baseNameOf path))}"}"; }}"
		else path;

	aerials = "$HOME/Library/Application Support/com.apple.wallpaper/aerials/videos";

	# WallpaperAgent's store with one choice for every display and Space, the way System Settings
	# writes it; the choice's configuration and options are property lists kept as data
	setWallpaper = { provider, configuration ? null, options ? {}, downloads ? [] }:
		let
			data = key: variable: ''<key>${key}</key><data>''$${variable}</data>'';
			linked = "<dict><key>Type</key><string>linked</string><key>Linked</key><dict><key>Content</key><dict><key>Choices</key><array><dict><key>Provider</key><string>${provider}</string><key>Files</key><array/>${data "Configuration" "configuration"}</dict></array>${data "EncodedOptionValues" "options"}<key>Shuffle</key><string>$null</string></dict><key>LastSet</key><date>$now</date><key>LastUse</key><date>$now</date></dict></dict>";
			index = ''<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict><key>AllSpacesAndDisplays</key>${linked}<key>SystemDefault</key>${linked}<key>Displays</key><dict/><key>Spaces</key><dict/></dict></plist>'';
			encoded = name: value:
				if value == null then "${name}=''"
				else ''
					printf '%s' ${q (plist value)} > "$work/${name}.plist"
					/usr/bin/plutil -convert binary1 "$work/${name}.plist"
					${name}=$(/usr/bin/base64 < "$work/${name}.plist")
				'';
		in
		# System Settings downloads an aerial when it's picked; here it's downloaded before it's set
		map (video: ''
			if [ ! -f "${aerials}/${video.id}.mov" ]; then
				/bin/mkdir -p "${aerials}"
				/usr/bin/curl -sfL -o "${aerials}/${video.id}.mov.part" ${q video.url} && /bin/mv "${aerials}/${video.id}.mov.part" "${aerials}/${video.id}.mov" \
					|| echo "nix-plist-manager: couldn't download the wallpaper ${video.id}" >&2
			fi
		'') downloads
		++ [ ''
			work=$(/usr/bin/mktemp -d)
			${encoded "configuration" configuration}
			${encoded "options" { values = options; }}
			now=$(/bin/date -u +%Y-%m-%dT%H:%M:%SZ)
			printf '%s' "${lib.replaceStrings [ "\"" "$null" ] [ "\\\"" "\\$null" ] index}" > "$work/Index.plist"
			/usr/bin/plutil -convert binary1 "$work/Index.plist"
			/bin/mkdir -p "$HOME/Library/Application Support/com.apple.wallpaper/Store"
			/bin/mv "$work/Index.plist" "$HOME/Library/Application Support/com.apple.wallpaper/Store/Index.plist"
			/bin/rm -rf "$work"
		'' ];

	placements = { "Fill Screen" = "Crop"; "Fit to Screen" = "SizeToFit"; "Stretch to Fill Screen" = "FillScreen"; Center = "Centered"; Tile = "Tile"; };
	shuffleFrequencies = {
		"On Login" = "shuffle_on_login"; "On Wakeup" = "shuffle_on_wakeup"; "Every 5 Seconds" = "shuffle_every_5_seconds";
		"Every Minute" = "shuffle_every_1_minute"; "Every 5 Minutes" = "shuffle_every_5_minutes";
		"Every 15 Minutes" = "shuffle_every_15_minutes"; "Every 30 Minutes" = "shuffle_every_30_minutes";
		"Every Hour" = "shuffle_every_1_hour"; "Every Day" = "shuffle_every_1_day";
	};
	aerialShuffleFrequencies = {
		Continuously = "shuffle_continuously"; "Every 12 Hours" = "shuffle_every_12_hours"; "Every Day" = "shuffle_every_1_day";
		"Every 2 Days" = "shuffle_every_2_days"; "Every Week" = "shuffle_every_1_week"; "Every Month" = "shuffle_every_1_month";
	};
	appearances = { Automatic = "automatic"; Light = "light"; Dark = "dark"; };
	macintoshColors = {
		Spectrum = "spectrum"; Random = "random"; Accent = "accent"; Green = "green"; Yellow = "yellow"; Orange = "orange";
		Red = "red"; Purple = "purple"; Blue = "blue"; Gray = "gray"; "Dark Gray" = "darkGray";
	};
	colors = {
		Black = "black"; "Blue Violet" = "blueViolet"; Cyan = "cyan"; "Dusty Rose" = "dustyRose"; "Electric Blue" = "electricBlue";
		"Gold 2" = "gold2"; Gold = "gold"; Ocher = "ocher"; Plum = "plum"; "Red Orange" = "redOrange"; "Rose Gold" = "roseGold";
		Silver = "silver"; "Soft Pink" = "softPink"; "Space Gray Pro" = "spaceGrayPro"; "Space Gray" = "spaceGray";
	};
	goldenGate = catalog.dynamic."17647EAB-8357-48B0-BCD6-B892194267C5";

	# a name, or the name with its options; `name` is the option that says which
	choice = { name, names, options, examples }: {
		kind = "wallpaper";
		normalize = value: lib.mapAttrs (_: option: option.default) (lib.filterAttrs (_: option: option.default != null) options)
			// (if lib.isAttrs value then value else { ${names} = value; });
		type = lib.types.coercedTo name (value: { ${names} = value; }) (lib.types.submodule { options = options; });
		choices = [];
		inherit examples;
		encode = _: _: [];
		fromName = builtins.fromJSON;
	};
	option = type: default: description: lib.mkOption { inherit type default description; };
	oneOf = table: lib.types.enum (lib.attrNames table);

	kinds = [ "dynamicWallpaper" "aerial" "picture" "color" "photo" "photos" "wallpaper" ];
	wallpaper = kind: { ui, description, value, apply, storage ? store, canUnset ? false }: setting {
		inherit ui description value storage canUnset;
		behaviors = lib.optional (apply != null) (appliesThrough (v: apply ((value.normalize or lib.id) v))) ++ [ (restarts "WallpaperAgent") ];
		relations = map (other: conflictsWith "applications.systemSettings.wallpaper.${other}" (_: true) "only one wallpaper can be set")
			(lib.remove kind kinds);
	};

	screenSaverDelays = {
		"After 1 minute" = 60; "After 2 minutes" = 120; "After 3 minutes" = 180; "After 5 minutes" = 300;
		"After 10 minutes" = 600; "After 20 minutes" = 1200; "After 30 minutes" = 1800; "After 1 hour" = 3600;
		"After 1 hour, 30 minutes" = 5400; "After 2 hours" = 7200; "After 2 hours, 30 minutes" = 9000;
		"After 3 hours" = 10800; Never = 0;
	};
in
{
	dynamicWallpaper = wallpaper "dynamicWallpaper" {
		ui = [ "System Settings" "Wallpaper" "Dynamic Wallpapers" ];
		description = ''
			A dynamic wallpaper that comes with macOS: "Golden Gate", "Sequoia", "Sonoma" or "Macintosh",
			or `{ name = "Macintosh"; appearance = "Dark"; color = "Blue"; }`. `color` is Macintosh's.
		'';
		value = choice {
			name = lib.types.enum [ "Golden Gate" "Sequoia" "Sonoma" "Macintosh" ];
			names = "name";
			examples = [ "Golden Gate" { name = "Macintosh"; appearance = "Dark"; color = "Blue"; } ];
			options = {
				name = option (lib.types.enum [ "Golden Gate" "Sequoia" "Sonoma" "Macintosh" ]) null "The wallpaper.";
				appearance = option (oneOf appearances) "Automatic" "Light, Dark, or following the appearance.";
				color = option (oneOf macintoshColors) "Spectrum" "Macintosh's colors.";
			};
		};
		apply = wallpaper:
			if wallpaper.name == "Golden Gate" then
				let
					variant = { Automatic = null; Light = goldenGate.light; Dark = goldenGate.dark; }.${wallpaper.appearance};
				in
				setWallpaper {
					provider = "com.apple.wallpaper.choice.aerials";
					configuration.assetID = if variant == null then "17647EAB-8357-48B0-BCD6-B892194267C5" else variant.id;
					options.aerialVariant = picker (if variant == null then "automatic" else variant.id);
					downloads = if variant == null then [ goldenGate.light goldenGate.dark ] else [ variant ];
				}
			else
				setWallpaper {
					provider = "com.apple.wallpaper.choice.${lib.toLower wallpaper.name}";
					options = { appearanceMode = picker appearances.${wallpaper.appearance}; }
						// lib.optionalAttrs (wallpaper.name == "Macintosh") { colorScheme = picker macintoshColors.${wallpaper.color}; };
				};
	};

	aerial = wallpaper "aerial" {
		ui = [ "System Settings" "Wallpaper" "Aerials" ];
		description = ''
			An aerial from Landscape, Cityscape, Underwater, Earth or Mac, by the name System Settings shows,
			e.g. "Tahoe Day"; it's downloaded when it's set, like picking it in System Settings does. Or a
			shuffle, `{ name = "Shuffle Landscape"; shuffle = "Every Week"; }`, which doesn't download the
			aerials it rotates through in advance.
		'';
		value = choice {
			name = oneOf (catalog.aerials // catalog.shuffles);
			names = "name";
			examples = [ "Tahoe Day" { name = "Shuffle Landscape"; shuffle = "Every Week"; } ];
			options = {
				name = option (oneOf (catalog.aerials // catalog.shuffles)) null "The aerial, or a shuffle.";
				shuffle = option (oneOf aerialShuffleFrequencies) "Every Day" "How often a shuffle changes.";
			};
		};
		apply = wallpaper:
			if catalog.shuffles ? ${wallpaper.name} then
				setWallpaper {
					provider = "com.apple.wallpaper.choice.aerials";
					configuration.assetID = catalog.shuffles.${wallpaper.name};
					options.aerialShuffleFrequency = picker aerialShuffleFrequencies.${wallpaper.shuffle};
				}
			else
				setWallpaper {
					provider = "com.apple.wallpaper.choice.aerials";
					configuration.assetID = catalog.aerials.${wallpaper.name}.id;
					downloads = [ catalog.aerials.${wallpaper.name} ];
				};
	};

	picture = wallpaper "picture" {
		ui = [ "System Settings" "Wallpaper" "Pictures" ];
		description = "A picture that comes with macOS, e.g. \"Radial Sky Blue\".";
		value = enum (lib.genAttrs catalog.pictures (name: name)) // { encode = _: _: []; };
		apply = name: setWallpaper {
			provider = "com.apple.wallpaper.choice.image";
			configuration = { type = "systemDesktopPicture"; url.relative = fileURL "/System/Library/Desktop Pictures/${name}.heic"; };
		};
	};

	color = wallpaper "color" {
		ui = [ "System Settings" "Wallpaper" "Colors" ];
		description = ''
			A color, e.g. "Plum", or "Random" for a different one from time to time:
			`{ name = "Random"; shuffle = "Every Hour"; randomly = true; gradient = false; }`.
		'';
		value = choice {
			name = oneOf (colors // { Random = null; });
			names = "name";
			examples = [ "Plum" { name = "Random"; shuffle = "Every Hour"; } ];
			options = {
				name = option (oneOf (colors // { Random = null; })) null "The color, or Random.";
				shuffle = option (oneOf shuffleFrequencies) "Every Day" "How often Random changes the color.";
				randomly = option lib.types.bool true "Whether Random picks colors in a random order.";
				gradient = option lib.types.bool false "Whether Random shows the colors as gradients.";
			};
		};
		apply = wallpaper:
			if wallpaper.name == "Random" then
				setWallpaper {
					provider = "com.apple.wallpaper.choice.color";
					configuration.type = "shuffle";
					options = {
						shuffleFrequency = picker shuffleFrequencies.${wallpaper.shuffle};
						shuffleRandomly = toggle wallpaper.randomly;
						shouldGenerateGradient = toggle wallpaper.gradient;
					};
				}
			else
				setWallpaper {
					provider = "com.apple.wallpaper.choice.color";
					configuration = { type = "systemColor"; systemColor.${colors.${wallpaper.name}} = {}; };
				};
	};

	photo = wallpaper "photo" {
		ui = [ "System Settings" "Wallpaper" "Your Photos" "Choose File…" ];
		description = ''
			A photo, e.g. `./wallpaper.jpg` next to your configuration, or
			`{ path = ./wallpaper.jpg; placement = "Fit to Screen"; }`. It's copied into the Nix store, so a
			new Mac built from your configuration gets it too.
		'';
		value = choice {
			name = lib.types.either lib.types.path lib.types.str;
			names = "path";
			examples = [ "/Users/me/Pictures/wallpaper.jpg" ];
			options = {
				path = option (lib.types.either lib.types.path lib.types.str) null "The photo.";
				placement = option (oneOf placements) "Fill Screen" "How the photo fills the screen.";
			};
		};
		apply = wallpaper: setWallpaper {
			provider = "com.apple.wallpaper.choice.image";
			configuration = { type = "imageFile"; url.relative = fileURL (inStore wallpaper.path); };
			options.placement = picker placements.${wallpaper.placement};
		};
	};

	photos = wallpaper "photos" {
		ui = [ "System Settings" "Wallpaper" "Your Photos" "Choose Folder…" ];
		description = ''
			A folder of photos to rotate through, e.g. `./wallpapers`, or
			`{ path = ./wallpapers; shuffle = "Every Hour"; randomly = true; placement = "Fill Screen"; }`.
			It's copied into the Nix store, so a new Mac built from your configuration gets it too.
		'';
		value = choice {
			name = lib.types.either lib.types.path lib.types.str;
			names = "path";
			examples = [ "/Users/me/Pictures/Wallpapers" ];
			options = {
				path = option (lib.types.either lib.types.path lib.types.str) null "The folder.";
				placement = option (oneOf placements) "Fill Screen" "How each photo fills the screen.";
				shuffle = option (oneOf shuffleFrequencies) "Every Day" "How often the photo changes.";
				randomly = option lib.types.bool false "Whether the photos come in a random order.";
			};
		};
		apply = wallpaper: setWallpaper {
			provider = "com.apple.wallpaper.choice.image";
			configuration = { type = "imageFolder"; url.relative = fileURL "${inStore wallpaper.path}/"; };
			options = {
				placement = picker placements.${wallpaper.placement};
				shuffleFrequency = picker shuffleFrequencies.${wallpaper.shuffle};
				shuffleRandomly = toggle wallpaper.randomly;
			};
		};
	};

	wallpaper = wallpaper "wallpaper" {
		ui = [ "System Settings" "Wallpaper" ];
		description = ''
			The wallpaper as picked in System Settings, captured with
			`nix run github:sushydev/nix-plist-manager#capture -- applications.systemSettings.wallpaper.wallpaper <directory>`.
			Your own photos are only referenced by their path, so set those with
			`applications.systemSettings.wallpaper.photo` or `.photos` instead.
		'';
		value = snapshot;
		storage.index = store;
		apply = null;
		canUnset = true;
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
