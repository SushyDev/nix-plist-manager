{ lib }:
let
	q = lib.escapeShellArg;
in
rec {
	appleScript = script: "/usr/bin/osascript -e ${q script} >/dev/null";

	jxa = script: "${jxaOutput script} >/dev/null";

	jxaOutput = script: "/usr/bin/osascript -l JavaScript -e ${q script}";

	skyLight = function: signature: argument: jxa (lib.concatStrings [
		"ObjC.import('Foundation');"
		"$.NSBundle.bundleWithPath('/System/Library/PrivateFrameworks/SkyLight.framework').load;"
		"ObjC.bindFunction('${function}', ${builtins.toJSON signature});"
		"$.${function}(${argument});"
	]);

	recentItems = amount: jxa (lib.concatStrings [
		"ObjC.import('CoreServices');"
		"ObjC.bindFunction('LSSharedFileListCreate', ['id', ['void *', 'id', 'void *']]);"
		"ObjC.bindFunction('LSSharedFileListSetProperty', ['int', ['id', 'id', 'id']]);"
		"['RecentApplications', 'RecentDocuments', 'RecentServers'].forEach(function (name) {"
		"  var list = $.LSSharedFileListCreate(null, $('com.apple.LSSharedFileList.' + name), null);"
		"  $.LSSharedFileListSetProperty(list, $('com.apple.LSSharedFileList.MaxAmount'), $(${toString amount}));"
		"});"
	]);

	inputSources = ids: jxa (lib.concatStrings [
		"ObjC.import('Carbon');"
		"var wanted = ${builtins.toJSON ids};"
		"var id = function (source) { return ObjC.castRefToObject($.TISGetInputSourceProperty(source, $.kTISPropertyInputSourceID)).js; };"
		"var isKeyboard = function (source) { return ObjC.castRefToObject($.TISGetInputSourceProperty(source, $.kTISPropertyInputSourceCategory)).js == 'TISCategoryKeyboardInputSource'; };"
		"var all = ObjC.castRefToObject($.TISCreateInputSourceList($(), true));"
		"var sources = []; for (var i = 0; i < all.count; i++) sources.push(all.objectAtIndex(i));"
		# enabling first leaves an input source to type with
		"sources.forEach(function (source) { if (wanted.indexOf(id(source)) >= 0) $.TISEnableInputSource(source); });"
		"var enabled = ObjC.castRefToObject($.TISCreateInputSourceList($(), false));"
		"for (var i = 0; i < enabled.count; i++) { var source = enabled.objectAtIndex(i);"
		"  if (isKeyboard(source) && wanted.indexOf(id(source)) < 0) $.TISDisableInputSource(source); }"
	]);

	enabledInputSources = jxaOutput (lib.concatStrings [
		"ObjC.import('Carbon');"
		"var list = ObjC.castRefToObject($.TISCreateInputSourceList($(), false)); var ids = [];"
		"for (var i = 0; i < list.count; i++) { var source = list.objectAtIndex(i);"
		"  if (ObjC.castRefToObject($.TISGetInputSourceProperty(source, $.kTISPropertyInputSourceCategory)).js == 'TISCategoryKeyboardInputSource')"
		"    ids.push(ObjC.castRefToObject($.TISGetInputSourceProperty(source, $.kTISPropertyInputSourceID)).js); }"
		"JSON.stringify(ids)"
	]);

	pmsetValue = source: key:
		"/usr/bin/pmset -g custom | /usr/bin/awk ${q "$0 == \"${source}:\" { found = 1; next } /^[^ ]/ { found = 0 } found && $1 == \"${key}\" { print $2 }"}";

	# The window server reads the appearance preferences only at login.
	appearance = {
		automatic = enabled: skyLight "SLSSetAppearanceThemeSwitchesAutomatically" [ "void" [ "bool" ] ] (lib.boolToString enabled);
		dark = enabled: appleScript "tell application \"System Events\" to tell appearance preferences to set dark mode to ${lib.boolToString enabled}";
	};
}
