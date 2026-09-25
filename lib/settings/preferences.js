ObjC.import('Foundation');

function read(path) {
	const contents = $.NSDictionary.dictionaryWithContentsOfFile(path);
	return contents.isNil() ? $.NSDictionary.dictionary : contents;
}

function text(path) {
	const contents = $.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null);
	return contents.isNil() ? '' : ObjC.unwrap(contents).trim();
}

// JSON numbers lose whether they were a real, and Nix only reads integers that fit in 64 bits, so
// those are written as literal number text
const literal = '\u0001';

// JSON can't hold data or dates, so they're written as base64 and ISO 8601 text
function plain(value) {
	if (value.isKindOfClass($.NSDictionary)) {
		const result = {};
		ObjC.unwrap(value.allKeys).forEach(key => { result[ObjC.unwrap(key)] = plain(value.objectForKey(key)); });
		return result;
	}
	if (value.isKindOfClass($.NSArray)) return ObjC.unwrap(value).map(plain);
	if (value.isKindOfClass($.NSData)) return ObjC.unwrap(value.base64EncodedStringWithOptions(0));
	if (value.isKindOfClass($.NSDate)) return ObjC.unwrap($.NSISO8601DateFormatter.alloc.init.stringFromDate(value));
	const unwrapped = ObjC.unwrap(value);
	if (typeof unwrapped !== 'number' || !Number.isInteger(unwrapped)) return unwrapped;
	if (!Number.isSafeInteger(unwrapped)) return literal + unwrapped.toExponential();
	return ['f', 'd'].includes(ObjC.unwrap(value.objCType)) ? literal + unwrapped.toFixed(1) : unwrapped;
}

function capture(file, key, out) {
	const exported = read(file);
	const value = key === null ? $() : exported.objectForKey(key);
	const kept = key === null ? exported : value.isNil() ? $.NSDictionary.dictionary : $.NSDictionary.dictionaryWithObjectForKey(value, key);
	$.NSPropertyListSerialization.dataWithPropertyListFormatOptionsError(kept, $.NSPropertyListXMLFormat_v1_0, 0, null)
		.writeToFileAtomically(out, true);
	return kept.count;
}

// Prints what the options store and their readers print, from the files `collect` exported into argv[0].
function run(argv) {
	const dir = argv[0];
	const manifest = JSON.parse(text(dir + '/manifest.json'));
	const state = { domains: {}, reads: {}, snapshots: {} };
	manifest.domains.forEach(({ id, file, keys }) => {
		const exported = read(dir + '/' + file);
		state.domains[id] = {};
		keys.filter(key => !exported.objectForKey(key).isNil()).forEach(key => { state.domains[id][key] = plain(exported.objectForKey(key)); });
	});
	manifest.reads.forEach(({ option, file }) => {
		const raw = text(dir + '/' + file);
		let json;
		try { json = JSON.parse(raw); } catch (error) { json = undefined; }
		state.reads[option] = json === undefined ? { raw } : { raw, json };
	});
	manifest.snapshots.forEach(({ option, directory, files }) => {
		$.NSFileManager.defaultManager.createDirectoryAtPathWithIntermediateDirectoriesAttributesError(directory, true, $(), null);
		files.forEach(({ file, key, out }) => {
			const count = capture(dir + '/' + file, key, directory + '/' + out);
			console.log('wrote ' + directory + '/' + out + ' (' + count + ' keys)');
		});
		state.snapshots[option] = directory;
	});
	return JSON.stringify(state).replace(new RegExp('"\\\\u0001([^"]*)"', 'g'), '$1');
}
