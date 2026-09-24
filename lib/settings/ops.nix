{ lib }:
# Plans stay plain data because the docs, optionIndex and the tools read them.
{
	write = key: value: { op = "write"; inherit key value; };

	delete = key: { op = "delete"; inherit key; };

	writeFlags = key: mask: bits: absent: { op = "writeFlags"; inherit key mask bits absent; };

	mergeDict = key: entries: { op = "mergeDict"; inherit key entries; };

	setMembers = key: members: { op = "setMembers"; inherit key members; };

	restore = key: file: { op = "restore"; inherit key file; };

	run = command: { op = "run"; inherit command; };

	afterwards = command: { op = "afterwards"; inherit command; };

	notify = name: { op = "notify"; inherit name; };

	restart = process: { op = "restart"; inherit process; discard = false; };

	restartDiscarding = process: { op = "restart"; inherit process; discard = true; };
}
