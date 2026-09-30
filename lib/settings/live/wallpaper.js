ObjC.import('Foundation');

const home = ObjC.unwrap($.NSHomeDirectory());
const path = home + '/Library/Application Support/com.apple.wallpaper/Store/Index.plist';

function toObjC(value) {
	if (Array.isArray(value)) {
		const array = $.NSMutableArray.array;
		value.forEach(item => array.addObject(toObjC(item)));
		return array;
	}
	if (typeof value === 'object') {
		if (value._data !== undefined) return $.NSData.alloc.initWithBase64EncodedStringOptions(value._data, 0);
		if (value._plist !== undefined) return $.NSPropertyListSerialization.dataWithPropertyListFormatOptionsError(toObjC(value._plist), $.NSPropertyListBinaryFormat_v1_0, 0, null);
		if (value._real !== undefined) return $.NSNumber.numberWithDouble(value._real);
		if (value._now !== undefined) return $.NSDate.date;
		const dictionary = $.NSMutableDictionary.dictionary;
		Object.keys(value).forEach(key => dictionary.setObjectForKey(toObjC(value[key]), key));
		return dictionary;
	}
	if (typeof value === 'boolean') return $.NSNumber.numberWithBool(value);
	if (typeof value === 'number') return $.NSNumber.numberWithLongLong(value);
	return $(value);
}

function album(name) {
	if (/^[0-9A-F-]{36}$/i.test(name)) return name;
	const app = Application.currentApplication();
	app.includeStandardAdditions = true;
	const library = home + '/Pictures/Photos Library.photoslibrary/database/Photos.sqlite';
	let found = '';
	try {
		found = app.doShellScript("/usr/bin/sqlite3 -readonly " + quoted(library) + " " + quoted(
			"select ZUUID from ZGENERICALBUM where ZKIND = 2 and ZTRASHEDSTATE = 0 and ZTITLE = '" + name.replace(/'/g, "''") + "' limit 1"));
	} catch (error) {
		throw new Error("couldn't read your Photos library to find the album " + name + "; give the terminal Full Disk Access, or set the album's identifier");
	}
	if (!found) throw new Error('there is no album named ' + name + ' in Photos');
	return found;
}

function quoted(text) {
	return "'" + text.replace(/'/g, "'\\''") + "'";
}

function entry(choice) {
	const configuration = choice.album ? Object.assign({}, choice.configuration, { identifier: album(choice.album) }) : choice.configuration;
	return toObjC({
		Type: 'linked',
		Linked: {
			Content: {
				Choices: [{ Provider: choice.provider, Files: [], Configuration: configuration ? { _plist: configuration } : { _data: '' } }],
				EncodedOptionValues: { _plist: { values: choice.options } },
				Shuffle: '$null',
			},
			LastSet: { _now: true },
			LastUse: { _now: true },
		},
	});
}

// Mission Control numbers each display's Desktops from 1
function desktops() {
	const spaces = ObjC.deepUnwrap($.NSUserDefaults.standardUserDefaults.persistentDomainForName('com.apple.spaces'));
	const monitors = spaces ? spaces.SpacesDisplayConfiguration['Management Data'].Monitors : [];
	return [].concat(...monitors.map(monitor =>
		(monitor.Spaces || []).filter(space => space.type === 0).map((space, at) => ({ uuid: space.uuid, number: at + 1 }))));
}

function linked(value) {
	return !value.isNil() && value.isKindOfClass($.NSDictionary) && ObjC.unwrap(value.objectForKey('Type')) === 'linked';
}

function run(argv) {
	const wanted = JSON.parse(argv[0]);
	let index = $.NSMutableDictionary.dictionaryWithContentsOfFile(path);
	if (index.isNil()) index = $.NSMutableDictionary.dictionary;

	if (wanted.all) {
		const all = entry(wanted.all);
		index.setObjectForKey(all, 'AllSpacesAndDisplays');
		index.setObjectForKey(all, 'SystemDefault');
		index.setObjectForKey($.NSMutableDictionary.dictionary, 'Displays');
		index.setObjectForKey($.NSMutableDictionary.dictionary, 'Spaces');
	}

	if (wanted.spaces) {
		const numbered = desktops();
		Object.keys(wanted.spaces).filter(number => !numbered.some(desktop => desktop.number == number)).forEach(number =>
			console.log('nix-plist-manager: there is no Desktop ' + number + ' in Mission Control, so its wallpaper is set once it exists and you rebuild'));
		const previous = index.objectForKey('Spaces');
		const current = index.objectForKey('AllSpacesAndDisplays');
		const fallback = linked(current) ? current : index.objectForKey('SystemDefault');
		const spaces = $.NSMutableDictionary.dictionary;
		numbered.forEach(({ uuid, number }) => {
			const choice = wanted.spaces[number];
			const kept = !previous.isNil() && previous.isKindOfClass($.NSDictionary) ? previous.objectForKey(uuid) : $();
			const space = $.NSMutableDictionary.dictionary;
			space.setObjectForKey(choice ? entry(choice) : (kept.isNil() ? fallback : kept.objectForKey('Default')), 'Default');
			space.setObjectForKey($.NSMutableDictionary.dictionary, 'Displays');
			spaces.setObjectForKey(space, uuid);
		});
		if (!linked(index.objectForKey('SystemDefault'))) index.setObjectForKey(fallback, 'SystemDefault');
		index.setObjectForKey('$null', 'AllSpacesAndDisplays');
		index.setObjectForKey($.NSMutableDictionary.dictionary, 'Displays');
		index.setObjectForKey(spaces, 'Spaces');
	}

	const data = $.NSPropertyListSerialization.dataWithPropertyListFormatOptionsError(index, $.NSPropertyListBinaryFormat_v1_0, 0, null);
	$.NSFileManager.defaultManager.createDirectoryAtPathWithIntermediateDirectoriesAttributesError($(path).stringByDeletingLastPathComponent, true, $(), null);
	data.writeToFileAtomically(path, true);
}
