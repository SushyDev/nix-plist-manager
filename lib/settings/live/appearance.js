ObjC.import('Foundation');

// The window server reads the appearance preferences only at login.
function run(argv) {
	const wanted = JSON.parse(argv[0]);
	$.NSBundle.bundleWithPath('/System/Library/PrivateFrameworks/SkyLight.framework').load;
	ObjC.bindFunction('SLSSetAppearanceThemeSwitchesAutomatically', ['void', ['bool']]);
	$.SLSSetAppearanceThemeSwitchesAutomatically(wanted.automatic);
	if (!wanted.automatic) Application('System Events').appearancePreferences.darkMode = wanted.dark;
}
