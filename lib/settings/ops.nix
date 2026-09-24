{ lib }:
# A plan is a list of these operations. Settings produce plans, behaviors rewrite them and
# render.nix turns the combined plan of every setting into one activation script. Keep them
# plain data: docs, optionIndex and tools/verify.py read them too.
{
	write = key: value: { op = "write"; inherit key value; };

	delete = key: { op = "delete"; inherit key; };

	# read-modify-write of an integer bitmask: bits outside `mask` keep their current value;
	# `absent` is what a missing key means
	writeFlags = key: mask: bits: { op = "writeFlags"; inherit key mask bits; absent = 0; };

	# set some entries of a dictionary, leaving the others as they are
	mergeDict = key: entries: { op = "mergeDict"; inherit key entries; };

	# add items to, or remove them from, an array of strings: { <item> = true (listed) or false; },
	# leaving other items as they are
	setMembers = key: members: { op = "setMembers"; inherit key members; };

	# replace a whole domain, or one key, with what a plist file holds; an empty file deletes
	restore = key: file: { op = "restore"; inherit key file; };

	run = command: { op = "run"; inherit command; };

	# a command run once at the very end, however many settings ask for it
	afterwards = command: { op = "afterwards"; inherit command; };

	# collected and deduplicated, run after every write
	notify = name: { op = "notify"; inherit name; };
	restart = process: { op = "restart"; inherit process; discard = false; };

	# for processes that save their own state when they quit, which would undo what was written
	restartDiscarding = process: { op = "restart"; inherit process; discard = true; };
}
