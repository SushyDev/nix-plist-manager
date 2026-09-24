{ lib }:
let
	s = import ./. { inherit lib; };
	inherit (s) setting global user system byHost stored bool inverted number enum flags absent
		restarts notifies appliesThrough onlyWhen allowedWhen conflictsWith implies domain snapshot storedAs;

	steps = plan: map (step: removeAttrs step [ "key" ] // lib.optionalAttrs (step ? key) {
		key = "${lib.optionalString step.key.byHost "ByHost "}${step.key.domain} ${step.key.name}";
	}) plan;

	tree = {
		tint = setting {
			ui = [ "Appearance" "Tint" ];
			storage = global "AppleReduceDesktopTinting";
			value = inverted bool;
		};
		accent = setting {
			ui = [ "Appearance" "Color" ];
			storage = { color = global "AppleAccentColor"; variant = global "AppleAquaColorVariant"; };
			value = enum {
				Multicolor = { color = absent; variant = 1; };
				Graphite = { color = -1; variant = 6; };
			};
			behaviors = [ (notifies "AppleColorPreferencesChangedNotification") ];
		};
		highlight = setting {
			ui = [ "Appearance" "Highlight" ];
			storage = global "AppleHighlightColor";
			value = enum { Automatic = absent; Blue = "0.7 0.8 1.0 Blue"; };
			relations = [
				(allowedWhen "Automatic" "accent" (color: color == "Multicolor") "needs Multicolor")
			];
		};
		size = setting {
			ui = [ "Dock" "Size" ];
			storage = user "com.apple.dock" "tilesize";
			value = number { min = 16; max = 128; stored = "float"; };
			behaviors = [ (restarts "Dock") ];
		};
		magnificationSize = setting {
			ui = [ "Dock" "Magnification" ];
			storage = user "com.apple.dock" "largesize";
			value = number { min = 16; max = 128; };
			behaviors = [ (restarts "Dock") ];
			relations = [ (implies "magnification" true "the slider turns magnification on") ];
		};
		magnification = setting {
			ui = [ "Dock" "Magnification" ];
			storage = user "com.apple.dock" "magnification";
			value = bool;
			behaviors = [ (restarts "Dock") ];
		};
		folder = setting {
			ui = [ "Appearance" "Folder color" ];
			storage = global "AppleIconAppearanceTintColor";
			value = enum { Red = "Red"; };
			relations = [ (onlyWhen "style" (style: style == "Tinted") "only used by Tinted") ];
		};
		style = setting {
			ui = [ "Appearance" "Style" ];
			storage = global "AppleIconAppearanceTheme";
			value = enum { Tinted = "TintedLight"; Clear = "ClearLight"; };
		};
		module = setting {
			ui = [ "Menu Bar" "Module" ];
			storage = byHost (user "com.apple.controlcenter" "Module");
			value = flags { showInMenuBar = 2; showInControlCenter = 1; };
		};
		updates = setting {
			ui = [ "General" "Software Update" "Download" ];
			storage = system "com.apple.SoftwareUpdate" "AutomaticDownload";
			value = bool;
		};
		live = setting {
			ui = [ "Appearance" "Mode" ];
			storage = global "AppleInterfaceStyle";
			value = enum { Dark = "Dark"; };
			behaviors = [ (appliesThrough (value: "set-mode ${value}")) ];
		};
		layout = setting {
			ui = [ "Menu Bar" "Layout" ];
			storage = {
				modules = byHost (domain "com.apple.controlcenter");
				positions = user "~/Library/Group Containers/com.apple.MenuBar/Library/Preferences/com.apple.MenuBar" "TrailingItemPreferredPositions";
			};
			value = snapshot;
			behaviors = [ (restarts "ControlCenter") ];
		};
		showDate = setting {
			ui = [ "Clock" "Show date" ];
			storage = user "com.apple.menuextra.clock" "ShowDate";
			value = storedAs { true = 1; false = 2; } bool;
		};
	};

	build = values: s.module.build { inherit tree values; scope = "user"; };
in
lib.runTests {
	testInvertedBool = {
		expr = steps (tree.tint.plan true);
		expected = [
			{ op = "write"; key = "NSGlobalDomain AppleReduceDesktopTinting"; value = false; }
			{ op = "delete"; key = "ByHost NSGlobalDomain AppleReduceDesktopTinting"; }
		];
	};

	testUnsetDeletesEveryKey = {
		expr = map (step: step.op) (tree.accent.plan "unset");
		expected = [ "delete" "delete" "notify" "delete" "delete" ];
	};

	testEnumRecordWithAbsent = {
		expr = lib.take 2 (steps (tree.accent.plan "Multicolor"));
		expected = [
			{ op = "delete"; key = "NSGlobalDomain AppleAccentColor"; }
			{ op = "write"; key = "NSGlobalDomain AppleAquaColorVariant"; value = 1; }
		];
	};

	testNumberRangeIsStrict = {
		expr = map tree.size.option.type.check [ 16 128 15 129 "unset" null ];
		expected = [ true true false false true true ];
	};

	testNumberStoredAsFloat = {
		expr = s.render.script (lib.take 1 (tree.size.plan 48));
		expected = "/usr/bin/defaults write com.apple.dock tilesize -float 48 || echo 'nix-plist-manager: failed: /usr/bin/defaults write com.apple.dock tilesize -float 48' >&2";
	};

	testFlagsReadModifyWrite = {
		expr = lib.head (tree.module.plan { showInMenuBar = true; showInControlCenter = null; });
		expected = {
			op = "writeFlags";
			key = tree.module.keys.value;
			mask = 2;
			bits = 2;
			absent = 0;
		};
	};

	testByHostKeysAreNotCleared = {
		expr = lib.length (tree.module.plan { showInMenuBar = false; showInControlCenter = false; });
		expected = 1;
	};

	testSystemScope = {
		expr = {
			inherit (tree.updates) scope;
			user = (build { updates = true; }).plan;
		};
		expected = { scope = "system"; user = []; };
	};

	testAppliesThroughReplacesWrites = {
		expr = steps (tree.live.plan "Dark");
		expected = [
			{ op = "run"; command = "set-mode Dark"; }
			{ op = "delete"; key = "ByHost NSGlobalDomain AppleInterfaceStyle"; }
		];
	};

	testRestartsOnce = {
		expr = lib.length (lib.filter (lib.hasPrefix "/usr/bin/killall")
			(lib.splitString "\n" (build { size = 48; magnification = true; }).script));
		expected = 1;
	};

	testAllowedWhenAsserts = {
		expr = map (a: a.message) (build { highlight = "Automatic"; accent = "Graphite"; }).assertions;
		expected = [ ''nix-plist-manager: highlight = "Automatic" can't be combined with accent = "Graphite": needs Multicolor.'' ];
	};

	testAllowedWhenSatisfied = {
		expr = with build { highlight = "Automatic"; accent = "Multicolor"; }; assertions ++ warnings;
		expected = [];
	};

	testOnlyWhenWarnsWhenUnmanaged = {
		expr = lib.length (build { folder = "Red"; }).warnings;
		expected = 1;
	};

	testIgnoreWarnings = {
		expr = (s.module.build { inherit tree; values = { folder = "Red"; }; scope = "user"; ignoreWarnings = [ "folder" ]; }).warnings;
		expected = [];
	};

	testImpliesWritesTheOtherSetting = {
		expr = let result = build { magnificationSize = 64; }; in {
			warnings = lib.length result.warnings;
			writesMagnification = lib.any (step: step.op == "write" && step.key.name == "magnification" && step.value) result.plan;
		};
		expected = { warnings = 1; writesMagnification = true; };
	};

	testImpliesConflictAsserts = {
		expr = lib.length (build { magnificationSize = 64; magnification = false; }).assertions;
		expected = 1;
	};

	testSnapshotRestoresDomainsAndKeys = {
		expr = map (step: lib.concatStringsSep " " (map toString [ step.op (step.key.domain or "") (step.key.name or "") (step.file or "") ]))
			(tree.layout.plan "/snapshot");
		expected = [
			"restore com.apple.controlcenter  /snapshot/modules.plist"
			"restore ~/Library/Group Containers/com.apple.MenuBar/Library/Preferences/com.apple.MenuBar TrailingItemPreferredPositions /snapshot/positions.plist"
			"restart   "
		];
	};

	testHomeRelativeDomains = {
		expr = lib.hasInfix "import \"$HOME\"/'Library/Group Containers/" (s.render.script (tree.layout.plan "/snapshot"));
		expected = true;
	};

	testStoredAs = {
		expr = map (step: step.value or null) (tree.showDate.plan false);
		expected = [ 2 null ];
	};

	testValuesWithSpacesAreQuoted = {
		expr = lib.hasInfix "-string '0.7 0.8 1.0 Blue'" (build { highlight = "Blue"; }).script;
		expected = true;
	};

	testArraysAndDictionariesAreTyped = {
		expr = map (step: s.render.script [ step ]) [
			(s.ops.write (global "AppleLanguages") [ "en-US" "nl-NL" ])
			(s.ops.write (global "AppleFirstWeekday") { gregorian = 2; })
		];
		expected = [
			"/usr/bin/defaults write NSGlobalDomain AppleLanguages -array -string en-US -string nl-NL || echo 'nix-plist-manager: failed: /usr/bin/defaults write NSGlobalDomain AppleLanguages -array -string en-US -string nl-NL' >&2"
			"/usr/bin/defaults write NSGlobalDomain AppleFirstWeekday -dict gregorian -int 2 || echo 'nix-plist-manager: failed: /usr/bin/defaults write NSGlobalDomain AppleFirstWeekday -dict gregorian -int 2' >&2"
		];
	};

	testDictSwitchesMergeOnlySetEntries = {
		expr = (s.dictSwitches { zoom = "feature.zoom"; voiceOver = "feature.voiceOver"; }).encode
			{ value = global "features"; } { zoom = false; voiceOver = null; };
		expected = [ (s.ops.mergeDict (global "features") { "feature.zoom" = false; }) ];
	};

	testMembersListOnlySetItems = {
		expr = (s.members { items = { tips = "com.apple.tips"; files = "System.files"; }; listedWhen = false; }).encode
			{ value = global "rules"; } { tips = false; files = null; };
		expected = [ (s.ops.setMembers (global "rules") { "com.apple.tips" = true; }) ];
	};

	testMembersRenderReadModifyWrite = {
		expr = lib.hasInfix "items.splice(at, 1)" (s.render.script [ (s.ops.setMembers (s.user "com.apple.Spotlight" "EnabledPreferenceRules") { a = false; }) ]);
		expected = true;
	};

	testNestedValuesAreWrittenAsPlist = {
		expr = lib.hasInfix "-dict-add 32 '<dict><key>enabled</key><false/></dict>'"
			(s.render.script [ (s.ops.mergeDict (s.user "com.apple.symbolichotkeys" "AppleSymbolicHotKeys") { "32" = { enabled = false; }; }) ]);
		expected = true;
	};

	testAfterwardsRunsOnceAtTheEnd = {
		expr = lib.last (lib.splitString "\n" (s.render.script [ (s.ops.afterwards "x") (s.ops.restart "Dock") (s.ops.afterwards "x") ]));
		expected = "x";
	};

	testInDictMergesOneEntry = {
		expr = (s.inDict "global" (enum { Large = "XL"; Default = "DEFAULT"; })).encode { value = global "FontSizeCategory"; } "Large";
		expected = [ (s.ops.mergeDict (global "FontSizeCategory") { global = "XL"; }) ];
	};

	testInDictKeepsTheCodecsType = {
		expr = (s.inDict "on" bool).type.check true;
		expected = true;
	};
}
