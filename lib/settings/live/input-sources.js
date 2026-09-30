ObjC.import('Carbon');

function property(source, name) {
	return ObjC.castRefToObject($.TISGetInputSourceProperty(source, name)).js;
}

function sources(includeDisabled) {
	const list = ObjC.castRefToObject($.TISCreateInputSourceList($(), includeDisabled));
	return Array.from({ length: list.count }, (_, at) => list.objectAtIndex(at));
}

const isKeyboard = source => property(source, $.kTISPropertyInputSourceCategory) === 'TISCategoryKeyboardInputSource';
const id = source => property(source, $.kTISPropertyInputSourceID);

// With no argument, prints the enabled keyboard input sources.
function run(argv) {
	if (argv.length === 0) return JSON.stringify(sources(false).filter(isKeyboard).map(id));
	const wanted = JSON.parse(argv[0]);
	// enabling first leaves an input source to type with
	sources(true).filter(source => wanted.includes(id(source))).forEach(source => $.TISEnableInputSource(source));
	sources(false).filter(source => isKeyboard(source) && !wanted.includes(id(source))).forEach(source => $.TISDisableInputSource(source));
}
