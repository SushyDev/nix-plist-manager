{ lib, settingsLib, ... }:
# All of these are in NSGlobalDomain. Running apps pick changes up when they relaunch.
#
# System Settings deletes a key when the choice matches the region's default; these options
# always write it, so the result doesn't depend on the region.
let
	inherit (settingsLib) setting global bool text strings enum ops;

	pane = "com.apple.settings.general";
	open = [ "com.apple.systempreferences.general.languageAndRegion" ];

	# enum values that are dictionaries, written whole to the single key
	dictionaries = lib.mapAttrs (_: dictionary: { value = dictionary; });

	shows = control: labels: lib.genAttrs labels (label: { ${control} = label; });

	# U+202F NARROW NO-BREAK SPACE: System Settings stores and shows it for a space as group
	# separator; labels here use a plain space
	space = " ";

	# apps keep their preferences in their container when they're sandboxed
	# by the app's domain: cfprefsd puts a sandboxed app's preferences in its container
	appLanguages = id: languages:
		let
			q = lib.escapeShellArg;
			domain = q id;
		in
		if languages == [] then "/usr/bin/defaults delete ${domain} AppleLanguages 2>/dev/null || true"
		else "/usr/bin/defaults write ${domain} AppleLanguages -array ${lib.concatMapStringsSep " " (l: "-string ${q l}") languages}";

	# 0 decimal separator, 1 group separator, 10 and 17 the same for currency
	numberSymbols = decimal: group: { "0" = decimal; "1" = group; "10" = decimal; "17" = group; };
in
{
	preferredLanguages = setting {
		ui = [ "System Settings" "General" "Language & Region" "Preferred Languages" ];
		description = "Language tags in order of preference, the first being the primary language, e.g. [ \"en-US\" \"nl-NL\" ].";
		storage = global "AppleLanguages";
		value = strings;
	};

	region = setting {
		ui = [ "System Settings" "General" "Language & Region" "Region" ];
		description = ''
			The locale: the primary language, the region, and optionally the calendar, e.g.
			"en_NL", "en_US@rg=nlzzzz" (US English with the formats of the Netherlands) or
			"en_NL@calendar=japanese".
		'';
		storage = global "AppleLocale";
		value = text;
	};

	temperature = setting {
		ui = [ "System Settings" "General" "Language & Region" "Temperature" ];
		storage = global "AppleTemperatureUnit";
		value = enum { "Celsius (°C)" = "Celsius"; "Fahrenheit (°F)" = "Fahrenheit"; };
		verify = {
			inherit pane open;
			expect = {
				"Celsius (°C)" = { "AXRadioButton:Celsius (°C) + Temperature" = 1; };
				"Fahrenheit (°F)" = { "AXRadioButton:Fahrenheit (°F) + Temperature" = 1; };
			};
		};
	};

	measurementSystem = setting {
		ui = [ "System Settings" "General" "Language & Region" "Measurement system" ];
		storage = {
			units = global "AppleMeasurementUnits";
			metric = global "AppleMetricUnits";
		};
		value = enum {
			Metric = { units = "Centimeters"; metric = true; };
			US = { units = "Inches"; metric = false; };
			UK = { units = "Inches"; metric = true; };
		};
		verify = {
			inherit pane open;
			expect = lib.genAttrs [ "Metric" "US" "UK" ] (system: { "AXRadioButton:${system} + Measurement system" = 1; });
		};
	};

	firstDayOfWeek = setting {
		ui = [ "System Settings" "General" "Language & Region" "First day of week" ];
		storage = global "AppleFirstWeekday";
		value = enum (dictionaries (lib.listToAttrs (lib.imap1 (number: day: lib.nameValuePair day { gregorian = number; })
			[ "Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" ])));
		verify = {
			inherit pane open;
			expect = shows "AXPopUpButton:first-weekday" [ "Monday" "Sunday" ];
		};
	};

	# labels show 19 August 2026, as System Settings does
	dateFormat = setting {
		ui = [ "System Settings" "General" "Language & Region" "Date format" ];
		storage = global "AppleICUDateFormatStrings";
		value = enum (dictionaries (lib.mapAttrs (_: pattern: { "1" = pattern; }) {
			"19/08/2026" = "dd/MM/y";
			"8/19/26" = "M/d/yy";
			"19/8/26" = "d/M/yy";
			"8/19/2026" = "M/d/y";
			"19.08.2026" = "dd.MM.y";
			"19-08-2026" = "dd-MM-y";
			"2026/8/19" = "y/M/d";
			"2026.08.19" = "y.MM.dd";
			"2026-08-19" = "y-MM-dd";
		}));
		verify = {
			inherit pane open;
			expect = shows "AXPopUpButton:date-format" [ "19/08/2026" "2026-08-19" ];
		};
	};

	numberFormat = setting {
		ui = [ "System Settings" "General" "Language & Region" "Number format" ];
		storage = global "AppleICUNumberSymbols";
		value = enum (dictionaries {
			"1,234,567.89" = numberSymbols "." ",";
			"1.234.567,89" = numberSymbols "," ".";
			"1 234 567.89" = numberSymbols "." space;
			"1 234 567,89" = numberSymbols "," space;
		});
		verify = {
			inherit pane open;
			expect = shows "AXPopUpButton:number-format" [ "1,234,567.89" "1.234.567,89" ];
		};
	};

	liveText = setting {
		ui = [ "System Settings" "General" "Language & Region" "Live Text" ];
		storage = global "AppleLiveTextEnabled";
		value = bool;
		verify = {
			inherit pane open;
			expect = {
				true = { "AXCheckBox:live-text" = 1; };
				false = { "AXCheckBox:live-text" = 0; };
			};
		};
	};

	# the Applications list: languages for single apps, by bundle identifier
	applications = setting {
		ui = [ "System Settings" "General" "Language & Region" "Applications" ];
		description = ''
			Languages for single apps, by bundle identifier, most preferred first, e.g.
			{ "com.spotify.client" = [ "nl" ]; }. An empty list makes the app follow the system again.
			Apps left out are left as they are.
		'';
		storage = global "AppleLanguages" // { domain = "~/Library/Preferences/<application>"; };
		value = {
			kind = "applications";
			type = lib.types.attrsOf (lib.types.listOf lib.types.str);
			choices = [];
			examples = [ { "com.example.app" = [ "nl" ]; } ];
			encode = _: apps: lib.mapAttrsToList (id: languages: ops.run (appLanguages id languages)) apps;
			fromName = builtins.fromJSON;
			read = { appLanguages = true; };
		};
		# unset has no single key to delete
		canUnset = false;
	};
}
