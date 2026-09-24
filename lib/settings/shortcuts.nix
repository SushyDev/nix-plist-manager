{ lib }:
# Keyboard shortcuts written the way people read them, "⌘⇧S", and what macOS stores for them:
#   - system shortcuts (com.apple.symbolichotkeys) keep [ character keyCode modifierFlags ]
#   - app shortcuts (NSUserKeyEquivalents) keep a key equivalent string like "@$s"
# A shortcut is any of ⌃⌥⇧⌘, in any order, followed by one key: a letter, digit or punctuation
# of the US layout, Space, Return, Tab, Delete, Escape, an arrow (← → ↑ ↓), Home, End, PageUp,
# PageDown, ForwardDelete or F1–F20.
let
	modifiers = {
		"⌃" = { flag = 262144; equivalent = "^"; };
		"⌥" = { flag = 524288; equivalent = "~"; };
		"⇧" = { flag = 131072; equivalent = "$"; };
		"⌘" = { flag = 1048576; equivalent = "@"; };
	};

	# keys that also carry this flag in symbolic hotkeys: arrows, F-keys and the navigation keys
	functionFlag = 8388608;

	# US layout key codes of the character keys
	characterKeyCodes = {
		a = 0; s = 1; d = 2; f = 3; h = 4; g = 5; z = 6; x = 7; c = 8; v = 9; b = 11; q = 12; w = 13;
		e = 14; r = 15; y = 16; t = 17; "1" = 18; "2" = 19; "3" = 20; "4" = 21; "6" = 22; "5" = 23;
		"=" = 24; "9" = 25; "7" = 26; "-" = 27; "8" = 28; "0" = 29; "]" = 30; o = 31; u = 32; "[" = 33;
		i = 34; p = 35; l = 37; j = 38; "'" = 39; k = 40; ";" = 41; "\\" = 42; "," = 43; "/" = 44;
		n = 45; m = 46; "." = 47; "`" = 50;
	};

	# the other keys: their key code, the character symbolic hotkeys store (65535 for none), and
	# the character of an app key equivalent (AppKit's function-key characters for most)
	namedKeys = let
		key = code: character: equivalent: function: { inherit code character equivalent function; };
		# a character by its code point, for those Nix strings have no escape for
		char = unicode: builtins.fromJSON ''"\u${unicode}"'';
		functionKey = code: unicode: key code 65535 (char unicode) true;
	in {
		Space = key 49 32 " " false;
		Return = key 36 65535 "\r" false;
		Tab = key 48 65535 "\t" false;
		Delete = key 51 65535 (char "0008") false;
		Escape = key 53 65535 (char "001b") false;
		"↑" = functionKey 126 "F700";
		"↓" = functionKey 125 "F701";
		"←" = functionKey 123 "F702";
		"→" = functionKey 124 "F703";
		ForwardDelete = functionKey 117 "F728";
		Home = functionKey 115 "F729";
		End = functionKey 119 "F72B";
		PageUp = functionKey 116 "F72C";
		PageDown = functionKey 121 "F72D";
	} // lib.listToAttrs (lib.imap1 (n: code: lib.nameValuePair "F${toString n}"
		(functionKey code (lib.toHexString (63236 + n - 1))))
		[ 122 120 99 118 96 97 98 100 101 109 103 111 105 107 113 106 64 79 80 90 ]);
in
rec {
	# "⌘⇧S" -> { modifiers = [ "⌘" "⇧" ]; key = "s"; } for a character key or { key = "F5"; } for a
	# named one; null when it isn't a shortcut
	parse = text:
		let
			glyph = lib.findFirst (glyph: lib.hasPrefix glyph text) null (lib.attrNames modifiers);
			rest = parse (lib.removePrefix glyph text);
		in
		if glyph != null then (if rest == null then null else rest // { modifiers = [ glyph ] ++ rest.modifiers; })
		else if characterKeyCodes ? ${lib.toLower text} then { modifiers = []; key = lib.toLower text; }
		else if namedKeys ? ${text} then { modifiers = []; key = text; }
		else null;

	isShortcut = text: parse text != null;

	# the option type for a shortcut
	type = lib.types.addCheck lib.types.str isShortcut // {
		description = ''a shortcut such as "⌘⇧S": ⌃⌥⇧⌘ followed by a key'';
	};

	# [ character keyCode modifierFlags ], as com.apple.symbolichotkeys keeps them
	hotKeyParameters = text:
		let
			shortcut = parse text;
			named = namedKeys.${shortcut.key} or null;
			flags = lib.foldl' builtins.bitOr (if named != null && named.function then functionFlag else 0)
				(map (glyph: modifiers.${glyph}.flag) shortcut.modifiers);
		in
		if named != null then [ named.character named.code flags ]
		else [ (lib.strings.charToInt shortcut.key) characterKeyCodes.${shortcut.key} flags ];

	# the NSUserKeyEquivalents string, modifiers first: "⌘⇧S" -> "@$s"
	keyEquivalent = text:
		let
			shortcut = parse text;
			# any order works
			ordered = lib.filter (glyph: lib.elem glyph shortcut.modifiers) [ "⌘" "⌃" "⌥" "⇧" ];
		in
		lib.concatMapStrings (glyph: modifiers.${glyph}.equivalent) ordered
		+ (namedKeys.${shortcut.key}.equivalent or shortcut.key);

	# for reading shortcuts back (`nix run .#current`): key code -> the key's name in a shortcut,
	# and modifier flag -> glyph
	names = {
		keys = lib.mapAttrs' (key: code: lib.nameValuePair (toString code) (lib.toUpper key)) characterKeyCodes
			// lib.mapAttrs' (name: key: lib.nameValuePair (toString key.code) name) namedKeys;
		modifiers = lib.mapAttrs' (glyph: modifier: lib.nameValuePair (toString modifier.flag) glyph) modifiers;
	};
}
