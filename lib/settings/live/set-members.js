ObjC.import('Foundation');

// defaults can't edit an array in place
function run(argv) {
	const { domain, key, members } = JSON.parse(argv[0]);
	const defaults = $.NSUserDefaults.alloc.initWithSuiteName(domain);
	const items = ObjC.deepUnwrap(defaults.arrayForKey(key)) || [];
	Object.keys(members).forEach(item => {
		const at = items.indexOf(item);
		if (members[item] && at < 0) items.push(item);
		if (!members[item] && at >= 0) items.splice(at, 1);
	});
	defaults.setObjectForKey($(items), key);
	defaults.synchronize;
}
