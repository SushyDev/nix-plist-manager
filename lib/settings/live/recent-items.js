ObjC.import('CoreServices');

function run(argv) {
	const amount = JSON.parse(argv[0]);
	ObjC.bindFunction('LSSharedFileListCreate', ['id', ['void *', 'id', 'void *']]);
	ObjC.bindFunction('LSSharedFileListSetProperty', ['int', ['id', 'id', 'id']]);
	['RecentApplications', 'RecentDocuments', 'RecentServers'].forEach(name => {
		const list = $.LSSharedFileListCreate(null, $('com.apple.LSSharedFileList.' + name), null);
		$.LSSharedFileListSetProperty(list, $('com.apple.LSSharedFileList.MaxAmount'), $(amount));
	});
}
