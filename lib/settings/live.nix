{ lib }:
# Commands for state a system service owns rather than reads from a plist, for use with
# `appliesThrough`. Kept here so each one is written and reviewed once.
let
	q = lib.escapeShellArg;
in
rec {
	appleScript = script: "/usr/bin/osascript -e ${q script} >/dev/null";

	# JavaScript for Automation, which unlike AppleScript can call C functions of frameworks
	jxa = script: "/usr/bin/osascript -l JavaScript -e ${q script} >/dev/null";

	# call a function of the private SkyLight framework (the window server's API)
	skyLight = function: signature: argument: jxa (lib.concatStrings [
		"ObjC.import('Foundation');"
		"$.NSBundle.bundleWithPath('/System/Library/PrivateFrameworks/SkyLight.framework').load;"
		"ObjC.bindFunction('${function}', ${builtins.toJSON signature});"
		"$.${function}(${argument});"
	]);

	# How many recent applications, documents and servers the Apple menu lists. The limit is a
	# property of those shared file lists, which sharedfilelistd keeps; this is the call that
	# changes it.
	recentItems = amount: jxa (lib.concatStrings [
		"ObjC.import('CoreServices');"
		"ObjC.bindFunction('LSSharedFileListCreate', ['id', ['void *', 'id', 'void *']]);"
		"ObjC.bindFunction('LSSharedFileListSetProperty', ['int', ['id', 'id', 'id']]);"
		"['RecentApplications', 'RecentDocuments', 'RecentServers'].forEach(function (name) {"
		"  var list = $.LSSharedFileListCreate(null, $('com.apple.LSSharedFileList.' + name), null);"
		"  $.LSSharedFileListSetProperty(list, $('com.apple.LSSharedFileList.MaxAmount'), $(${toString amount}));"
		"});"
	]);

	# Enable exactly these keyboard layouts and input methods (by input source id, e.g.
	# "com.apple.keylayout.US") and disable the other ones, through the Text Input Sources API
	# that System Settings uses: the input source server keeps them, and only writes the
	# preferences. Palettes such as the emoji viewer aren't touched.
	inputSources = ids: jxa (lib.concatStrings [
		"ObjC.import('Carbon');"
		"var wanted = ${builtins.toJSON ids};"
		"var id = function (source) { return ObjC.castRefToObject($.TISGetInputSourceProperty(source, $.kTISPropertyInputSourceID)).js; };"
		"var isKeyboard = function (source) { return ObjC.castRefToObject($.TISGetInputSourceProperty(source, $.kTISPropertyInputSourceCategory)).js == 'TISCategoryKeyboardInputSource'; };"
		"var all = ObjC.castRefToObject($.TISCreateInputSourceList($(), true));"
		"var sources = []; for (var i = 0; i < all.count; i++) sources.push(all.objectAtIndex(i));"
		# enable first, so there's always one left to type with
		"sources.forEach(function (source) { if (wanted.indexOf(id(source)) >= 0) $.TISEnableInputSource(source); });"
		"var enabled = ObjC.castRefToObject($.TISCreateInputSourceList($(), false));"
		"for (var i = 0; i < enabled.count; i++) { var source = enabled.objectAtIndex(i);"
		"  if (isKeyboard(source) && wanted.indexOf(id(source)) < 0) $.TISDisableInputSource(source); }"
	]);

	# the input sources that are enabled now, as a JSON list of ids
	enabledInputSources = "/usr/bin/osascript -l JavaScript -e ${q (lib.concatStrings [
		"ObjC.import('Carbon');"
		"var list = ObjC.castRefToObject($.TISCreateInputSourceList($(), false)); var ids = [];"
		"for (var i = 0; i < list.count; i++) { var source = list.objectAtIndex(i);"
		"  if (ObjC.castRefToObject($.TISGetInputSourceProperty(source, $.kTISPropertyInputSourceCategory)).js == 'TISCategoryKeyboardInputSource')"
		"    ids.push(ObjC.castRefToObject($.TISGetInputSourceProperty(source, $.kTISPropertyInputSourceID)).js); }"
		"JSON.stringify(ids)"
	])}";

	# one of powerd's settings for a power source ("Battery Power" or "AC Power"), as pmset reports it
	pmsetValue = source: key:
		"/usr/bin/pmset -g custom | /usr/bin/awk ${q "$0 == \"${source}:\" { found = 1; next } /^[^ ]/ { found = 0 } found && $1 == \"${key}\" { print $2 }"}";

	# Light, Dark and automatic appearance. The window server keeps this state and only reads
	# the preferences at login; System Settings goes through these calls, which update the
	# preferences too.
	appearance = {
		automatic = enabled: skyLight "SLSSetAppearanceThemeSwitchesAutomatically" [ "void" [ "bool" ] ] (lib.boolToString enabled);
		dark = enabled: appleScript "tell application \"System Events\" to tell appearance preferences to set dark mode to ${lib.boolToString enabled}";
	};
}
