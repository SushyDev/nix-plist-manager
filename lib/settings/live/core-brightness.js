ObjC.import('Foundation');

// corebrightnessd's state is root-only on disk, so it's changed through its client classes.
function run(argv) {
	const { client, method, arguments: values } = JSON.parse(argv[0]);
	$.NSBundle.bundleWithPath('/System/Library/PrivateFrameworks/CoreBrightness.framework').load;
	const instance = $.NSClassFromString(client).alloc.init;
	instance[method](...values);
}
