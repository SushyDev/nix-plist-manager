{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting domain snapshot restartsDiscardingItsState user byHost enum shows appliesThrough conflictsWith validates;
	q = lib.escapeShellArg;

	store = domain "~/Library/Application Support/com.apple.wallpaper/Store/Index";
	catalog = lib.importJSON ./wallpapers.json;

	picker = id: { picker._0 = { inherit id; }; };
	toggle = on: { toggle._0.isOn = on; };
	fileURL = path: "file://" + lib.concatMapStringsSep "/" lib.strings.escapeURL (lib.splitString "/" path);

	# a file in the flake is copied to the Nix store, under a name the store accepts
	inStore = path:
		if lib.isPath path then "${builtins.path { inherit path; name = "wallpaper${lib.optionalString (lib.pathIsRegularFile path) ".${lib.last (lib.splitString "." (baseNameOf path))}"}"; }}"
		else path;

	# System Settings downloads what a wallpaper needs when it's picked; here it's downloaded before it's set
	download = { url, to, member ? null }: ''
		dest="$HOME"/${q to}
		if [ ! -f "$dest" ]; then
			/bin/mkdir -p "$(/usr/bin/dirname "$dest")"
			{ /usr/bin/curl -sfL -o "$dest.download" ${q url} \
				&& ${if member == null then ''/bin/mv "$dest.download" "$dest.part"'' else ''/usr/bin/unzip -p "$dest.download" ${q member} > "$dest.part"''} \
				&& /bin/mv "$dest.part" "$dest"; } \
				|| echo ${q "nix-plist-manager: couldn't download the wallpaper ${baseNameOf to}"} >&2
			/bin/rm -f "$dest.download" "$dest.part"
		fi
	'';

	# WallpaperAgent's store, the way System Settings writes it: `all` for every display and Space, or
	# `spaces` for Desktops by their number in Mission Control
	setWallpaper = wanted:
		let
			choices = lib.optional (wanted ? all) wanted.all ++ lib.attrValues (wanted.spaces or {});
			written = choice: { configuration = null; options = {}; } // removeAttrs choice [ "downloads" "notes" ];
			input = lib.mapAttrs (name: value: if name == "all" then written value else lib.mapAttrs (_: written) value) wanted;
		in
		map download (lib.concatMap (choice: choice.downloads or []) choices)
		++ lib.concatMap (choice: choice.notes or []) choices
		++ [ "/usr/bin/osascript -l JavaScript -e ${q (builtins.readFile ./wallpaper.js)} ${q (builtins.toJSON input)} >/dev/null" ];

	aerialVideo = video: { inherit (video) url; to = "Library/Application Support/com.apple.wallpaper/aerials/videos/${video.id}.mov"; };
	assetPicture = picture: {
		inherit (picture) url;
		to = "Library/Application Support/com.apple.mobileAssetDesktop/${picture.asset}.heic";
		member = "AssetData/${picture.asset}.heic";
	};
	tahoeVideo = name:
		let
			words = builtins.match "([a-z]+)([A-Z][a-z]+)" name;
		in
		{
			url = catalog.tahoe.${name};
			to = "Library/Containers/com.apple.NeptuneOneExtension/Data/Library/Application Support/Videos/Tahoe ${lib.toSentenceCase (lib.head words)} ${lib.last words}.mov";
		};
	# only apps Apple entitles can have macOS install an asset, which is what System Settings checks
	pressDownload = name: dynamic: ''
		[ -d /System/Library/AssetsV2/com_apple_MobileAsset_DesktopPicture/${q (lib.removeSuffix ".zip" (baseNameOf dynamic.url))}.asset ] \
			|| echo ${q "nix-plist-manager: ${name} is your wallpaper, but System Settings shows it as not downloaded until you press Download next to it in Wallpaper"} >&2
	'';
	systemPicture = file: { type = "systemDesktopPicture"; url.relative = fileURL "/System/Library/Desktop Pictures/${file}"; };

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
	# the solar sets call Automatic "Dynamic"
	appearances = { Automatic = "automatic"; Dynamic = "automatic"; Light = "light"; Dark = "dark"; };
	macintoshColors = {
		Spectrum = "spectrum"; Random = "random"; Accent = "accent"; Green = "green"; Yellow = "yellow"; Orange = "orange";
		Red = "red"; Purple = "purple"; Blue = "blue"; Gray = "gray"; "Dark Gray" = "darkGray";
	};
	colors = {
		Black = "black"; "Blue Violet" = "blueViolet"; Cyan = "cyan"; "Dusty Rose" = "dustyRose"; "Electric Blue" = "electricBlue";
		"Gold 2" = "gold2"; Gold = "gold"; Ocher = "ocher"; Plum = "plum"; "Red Orange" = "redOrange"; "Rose Gold" = "roseGold";
		Silver = "silver"; "Soft Pink" = "softPink"; "Space Gray Pro" = "spaceGrayPro"; "Space Gray" = "spaceGray";
		Stone = "stone"; Teal = "teal"; "Turquoise Green" = "turquoiseGreen"; Yellow = "yellow";
	};
	hexColor = lib.types.strMatching "#[0-9A-Fa-f]{6}";
	# sRGB, as the color picker stores it
	sRGB = "YnBsaXN0MDAQBwgAAAAAAAABAQAAAAAAAAABAAAAAAAAAAAAAAAAAAAACg==";
	components = hex: map (at: { _real = lib.fromHexString (builtins.substring (1 + 2 * at) 2 hex) / 255.0; }) [ 0 1 2 ] ++ [ { _real = 1.0; } ];

	goldenGate = "17647EAB-8357-48B0-BCD6-B892194267C5";
	dynamicWallpapers = [ "Golden Gate" "Tahoe" "Sequoia" "Sonoma" "Macintosh" ] ++ lib.attrNames catalog.dynamic;

	# a name, or the name with its options; `names` is the option that says which
	choice = { name, names, options, examples }: {
		kind = "wallpaper";
		normalize = value: lib.mapAttrs (_: option: option.default) (lib.filterAttrs (_: option: option.default != null) options)
			// (if lib.isAttrs value then lib.filterAttrs (_: v: v != null) value else { ${names} = value; });
		type = lib.types.coercedTo name (value: { ${names} = value; }) (lib.types.submodule { options = options; });
		choices = [];
		inherit examples;
		encode = _: _: [];
		fromName = builtins.fromJSON;
	};
	option = type: default: description: lib.mkOption { inherit type default description; };
	oneOf = table: lib.types.enum (lib.attrNames table);
	pathOrString = lib.types.either lib.types.path lib.types.str;

	kinds = {
		dynamicWallpaper = {
			ui = [ "System Settings" "Wallpaper" "Dynamic Wallpapers" ];
			description = ''
				A dynamic wallpaper, by the name System Settings shows, e.g. "Tahoe", "Big Sur" or
				`{ name = "Macintosh"; appearance = "Dark"; color = "Blue"; }`. `appearance` is "Automatic" (the
				ones that follow the sun call it "Dynamic"), "Light" or "Dark"; `color` is Macintosh's. What
				macOS downloads when it's picked in System Settings is downloaded when it's set.
			'';
			value = choice {
				name = lib.types.enum dynamicWallpapers;
				names = "name";
				examples = [ "Tahoe" { name = "Macintosh"; appearance = "Dark"; color = "Blue"; } ];
				options = {
					name = option (lib.types.enum dynamicWallpapers) null "The wallpaper.";
					appearance = option (oneOf appearances) "Automatic" "Light, Dark, or following the appearance or the sun.";
					color = option (oneOf macintoshColors) "Spectrum" "Macintosh's colors.";
				};
			};
			choice = wallpaper:
				let
					appearance = appearances.${wallpaper.appearance};
					dynamic = catalog.dynamic.${wallpaper.name};
				in
				if wallpaper.name == "Golden Gate" then
					let
						variant = catalog.goldenGate.${appearance} or null;
					in
					{
						provider = "com.apple.wallpaper.choice.aerials";
						configuration.assetID = if variant == null then goldenGate else variant.id;
						options.aerialVariant = picker (if variant == null then "automatic" else variant.id);
						downloads = map aerialVideo (if variant == null then lib.attrValues catalog.goldenGate else [ variant ]);
					}
				else if wallpaper.name == "Tahoe" then {
					provider = "com.apple.NeptuneOneExtension";
					options.appearance = picker appearance;
					downloads = map tahoeVideo (lib.filter (name: appearance == "automatic" || lib.hasPrefix appearance name) (lib.attrNames catalog.tahoe));
				}
				else if catalog.dynamic ? ${wallpaper.name} then {
					provider = "com.apple.wallpaper.choice.dynamic";
					configuration = systemPicture "${dynamic.file}.madesktop";
					options.style = picker (if appearance == "automatic" && dynamic.solar then "dynamic" else appearance);
					downloads = [ (assetPicture dynamic) ];
					notes = [ (pressDownload wallpaper.name dynamic) ];
				}
				else {
					provider = "com.apple.wallpaper.choice.${lib.toLower wallpaper.name}";
					options = { appearanceMode = picker appearance; }
						// lib.optionalAttrs (wallpaper.name == "Macintosh") { colorScheme = picker macintoshColors.${wallpaper.color}; };
				};
		};

		aerial = {
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
			choice = wallpaper:
				if catalog.shuffles ? ${wallpaper.name} then {
					provider = "com.apple.wallpaper.choice.aerials";
					configuration.assetID = catalog.shuffles.${wallpaper.name};
					options.aerialShuffleFrequency = picker aerialShuffleFrequencies.${wallpaper.shuffle};
				}
				else {
					provider = "com.apple.wallpaper.choice.aerials";
					configuration.assetID = catalog.aerials.${wallpaper.name}.id;
					downloads = [ (aerialVideo catalog.aerials.${wallpaper.name}) ];
				};
		};

		picture = {
			ui = [ "System Settings" "Wallpaper" "Pictures" ];
			description = ''
				A picture, by the name System Settings shows, e.g. "Radial Sky Blue". What macOS downloads when
				it's picked in System Settings is downloaded when it's set.
			'';
			value = enum (lib.mapAttrs (name: _: name) catalog.pictures) // { encode = _: _: []; };
			choice = name:
				let
					picture = catalog.pictures.${name};
				in
				{
					provider = "com.apple.wallpaper.choice.image";
					configuration = systemPicture (if picture ? asset then "${picture.file}.madesktop" else "${picture.file}.heic");
					downloads = lib.optional (picture ? asset) (assetPicture picture);
				};
		};

		color = {
			ui = [ "System Settings" "Wallpaper" "Colors" ];
			description = ''
				A color, e.g. "Plum", your own as `"#1E90FF"`, or "Random" for a different one from time to time,
				e.g. `{ name = "Random"; shuffle = "Every Hour"; randomly = true; }`. `gradient` shows it as a
				gradient.
			'';
			value = choice {
				name = lib.types.either (oneOf (colors // { Random = null; })) hexColor;
				names = "name";
				examples = [ "Plum" "#1E90FF" { name = "Random"; shuffle = "Every Hour"; gradient = true; } ];
				options = {
					name = option (lib.types.nullOr (lib.types.either (oneOf (colors // { Random = null; })) hexColor)) null "The color, your own as \"#RRGGBB\", or Random.";
					shuffle = option (oneOf shuffleFrequencies) "Every Day" "How often Random changes the color.";
					randomly = option lib.types.bool true "Whether Random picks colors in a random order.";
					gradient = option lib.types.bool false "Whether the color is shown as a gradient.";
				};
			};
			choice = wallpaper:
				let
					gradient.shouldGenerateGradient = toggle wallpaper.gradient;
				in
				if wallpaper.name == "Random" then {
					provider = "com.apple.wallpaper.choice.color";
					configuration.type = "shuffle";
					options = gradient // {
						shuffleFrequency = picker shuffleFrequencies.${wallpaper.shuffle};
						shuffleRandomly = toggle wallpaper.randomly;
					};
				}
				else if colors ? ${wallpaper.name} then {
					provider = "com.apple.wallpaper.choice.color";
					configuration = { type = "systemColor"; systemColor.${colors.${wallpaper.name}} = {}; };
					options = gradient;
				}
				else {
					provider = "com.apple.wallpaper.choice.color";
					configuration.type = "customColor";
					options = gradient // {
						customColor.color._0.color = { components = components wallpaper.name; colorSpace._data = sRGB; };
					};
				};
		};

		photo = {
			ui = [ "System Settings" "Wallpaper" "Your Photos" "Choose File…" ];
			description = ''
				A photo, e.g. `./wallpaper.jpg` next to your configuration, or
				`{ path = ./wallpaper.jpg; placement = "Fit to Screen"; }`. It's copied into the Nix store, so a
				new Mac built from your configuration gets it too.
			'';
			value = choice {
				name = pathOrString;
				names = "path";
				examples = [ "/Users/me/Pictures/wallpaper.jpg" ];
				options = {
					path = option (lib.types.nullOr pathOrString) null "The photo.";
					placement = option (oneOf placements) "Fill Screen" "How the photo fills the screen.";
				};
			};
			choice = wallpaper: {
				provider = "com.apple.wallpaper.choice.image";
				configuration = { type = "imageFile"; url.relative = fileURL (inStore wallpaper.path); };
				options.placement = picker placements.${wallpaper.placement};
			};
		};

		photos = {
			ui = [ "System Settings" "Wallpaper" "Your Photos" ];
			description = ''
				Photos to rotate through: a folder, e.g. `./wallpapers`, which is copied into the Nix store so a
				new Mac built from your configuration gets it too, or an album in Photos,
				`{ album = "Vacation"; shuffle = "Every Hour"; randomly = true; placement = "Fill Screen"; }`.
				Finding an album by its name reads your Photos library, which needs Full Disk Access for the
				terminal you rebuild in.
			'';
			value = choice {
				name = pathOrString;
				names = "path";
				examples = [ "/Users/me/Pictures/Wallpapers" { album = "Vacation"; shuffle = "Every Hour"; } ];
				options = {
					path = option (lib.types.nullOr pathOrString) null "The folder.";
					album = option (lib.types.nullOr lib.types.str) null "The album in Photos, by its name.";
					placement = option (oneOf placements) "Fill Screen" "How each photo fills the screen.";
					shuffle = option (oneOf shuffleFrequencies) "Every Day" "How often the photo changes.";
					randomly = option lib.types.bool false "Whether the photos come in a random order.";
				};
			};
			problems = wallpaper: lib.optional ((wallpaper ? path) == (wallpaper ? album)) "set either a folder as `path` or an `album`";
			choice = wallpaper:
				let
					options = {
						placement = picker placements.${wallpaper.placement};
						shuffleFrequency = picker shuffleFrequencies.${wallpaper.shuffle};
						shuffleRandomly = toggle wallpaper.randomly;
					};
				in
				if wallpaper ? album then {
					provider = "com.apple.wallpaper.extension.photos";
					configuration.type = "collection";
					inherit (wallpaper) album;
					inherit options;
				}
				else {
					provider = "com.apple.wallpaper.choice.image";
					configuration = { type = "imageFolder"; url.relative = fileURL "${inStore wallpaper.path}/"; };
					inherit options;
				};
		};
	};

	normalize = kind: kind.value.normalize or lib.id;

	spaces = {
		kind = "wallpaper";
		type = lib.types.attrsOf (lib.types.submodule {
			options = lib.mapAttrs (_: kind: option (lib.types.nullOr kind.value.type) null kind.description) kinds;
		});
		choices = [];
		examples = [ { "1".photo = "/Users/me/Pictures/wallpaper.jpg"; "2".color = "Plum"; } ];
		encode = _: _: [];
		fromName = builtins.fromJSON;
	};

	problemsOf = name: value: (kinds.${name}.problems or (_: [])) (normalize kinds.${name} value);

	# One wallpaper for every Desktop, which `spaces` can change for some of them; a snapshot replaces both.
	# `spaces` is written after the others because options are applied in alphabetical order.
	forEveryDesktop = lib.attrNames kinds;
	excludes = lib.genAttrs forEveryDesktop (name: lib.remove name forEveryDesktop ++ [ "snapshot" ]) // {
		spaces = [ "snapshot" ];
		snapshot = forEveryDesktop ++ [ "spaces" ];
	};

	wallpaper = name: { ui, description, value, apply ? null, storage ? store, canUnset ? false, problems ? (_: []) }: setting {
		inherit ui description value storage canUnset;
		behaviors = lib.optional (apply != null) (appliesThrough apply) ++ [ (restartsDiscardingItsState "WallpaperAgent") ];
		relations = map (other: conflictsWith "applications.systemSettings.wallpaper.${other}" (_: true) "only one wallpaper can be set for every Desktop") excludes.${name}
			++ [ (validates problems) ];
	};

	chosen = space: lib.filterAttrs (_: value: value != null) space;

	screenSaverDelays = {
		"After 1 minute" = 60; "After 2 minutes" = 120; "After 3 minutes" = 180; "After 5 minutes" = 300;
		"After 10 minutes" = 600; "After 20 minutes" = 1200; "After 30 minutes" = 1800; "After 1 hour" = 3600;
		"After 1 hour, 30 minutes" = 5400; "After 2 hours" = 7200; "After 2 hours, 30 minutes" = 9000;
		"After 3 hours" = 10800; Never = 0;
	};
in
lib.mapAttrs (name: kind: wallpaper name {
	inherit (kind) ui description value;
	apply = value: setWallpaper { all = kind.choice (normalize kind value); };
	problems = problemsOf name;
}) kinds
// {
	spaces = wallpaper "spaces" {
		ui = [ "System Settings" "Wallpaper" "Show on all Spaces" ];
		description = ''
			A wallpaper for each Desktop, by its number in Mission Control, e.g.
			`{ "1".photo = ./work.jpg; "2".aerial = "Tahoe Day"; }`, with the same choices as the options
			above. The other Desktops keep the wallpaper that's set for all of them.
		'';
		value = spaces;
		apply = value: setWallpaper {
			spaces = lib.mapAttrs (_: space:
				let
					kind = lib.head (lib.attrNames (chosen space));
				in
				kinds.${kind}.choice (normalize kinds.${kind} space.${kind})
			) value;
		};
		problems = value: lib.concatLists (lib.mapAttrsToList (number: space:
			let
				set = lib.attrNames (chosen space);
			in
			lib.optional (builtins.match "[1-9][0-9]*" number == null) "\"${number}\" isn't the number of a Desktop"
			++ lib.optional (lib.length set != 1) "Desktop ${number} needs one wallpaper, not ${toString (lib.length set)}"
			++ map (problem: "Desktop ${number}'s ${problem}") (lib.concatMap (kind: map (problem: "${kind}: ${problem}") (problemsOf kind space.${kind})) set)
		) value);
	};

	snapshot = wallpaper "snapshot" {
		ui = [ "System Settings" "Wallpaper" ];
		description = ''
			The wallpaper as picked in System Settings, captured with
			`nix run github:sushydev/nix-plist-manager#capture -- applications.systemSettings.wallpaper.snapshot <directory>`.
			Your own photos are only referenced by their path, so set those with
			`applications.systemSettings.wallpaper.photo` or `.photos` instead.
		'';
		value = snapshot;
		storage.index = store;
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
