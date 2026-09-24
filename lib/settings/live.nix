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

	# Light, Dark and automatic appearance. The window server keeps this state and only reads
	# the preferences at login; System Settings goes through these calls, which update the
	# preferences too.
	appearance = {
		automatic = enabled: skyLight "SLSSetAppearanceThemeSwitchesAutomatically" [ "void" [ "bool" ] ] (lib.boolToString enabled);
		dark = enabled: appleScript "tell application \"System Events\" to tell appearance preferences to set dark mode to ${lib.boolToString enabled}";
	};
}
