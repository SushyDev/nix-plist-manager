ObjC.import('Foundation');
ObjC.import('CoreGraphics');

// The window server reads the appearance preferences only at login.
function run(argv) {
	const wanted = JSON.parse(argv[0]);

	// Without a window server session of its own (another user activated through sudo inherits
	// the caller's session), System Events can't reach this user (-1701), so write the
	// preferences the window server reads at login instead.
	ObjC.bindFunction('getuid', ['unsigned int', []]);
	const session = $.CGSessionCopyCurrentDictionary();
	const sessionUser = session && ObjC.deepUnwrap(ObjC.castRefToObject(session)).kCGSSessionUserIDKey;
	if (sessionUser !== $.getuid()) {
		const app = Application.currentApplication();
		app.includeStandardAdditions = true;
		app.doShellScript(
			wanted.automatic ? '/usr/bin/defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool true'
			: '/usr/bin/defaults delete -g AppleInterfaceStyleSwitchesAutomatically 2>/dev/null; ' + (wanted.dark
				? '/usr/bin/defaults write -g AppleInterfaceStyle Dark'
				: '/usr/bin/defaults delete -g AppleInterfaceStyle 2>/dev/null; true'));
		return;
	}

	$.NSBundle.bundleWithPath('/System/Library/PrivateFrameworks/SkyLight.framework').load;
	ObjC.bindFunction('SLSSetAppearanceThemeSwitchesAutomatically', ['void', ['bool']]);
	$.SLSSetAppearanceThemeSwitchesAutomatically(wanted.automatic);
	if (!wanted.automatic) Application('System Events').appearancePreferences.darkMode = wanted.dark;
}
