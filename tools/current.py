#!/usr/bin/env python3
"""
current — write this Mac's current settings as nix-plist-manager options.

    nix run .#current -- [--ui] [--snapshots <directory>] [--only <prefix>]
    nix run .#capture -- <option> <directory>

Prints two Nix attribute sets, one for home-manager and one for nix-darwin, with every option
whose value could be read: from the command a setting reads through, from the preferences it
writes (for a fixed set of values, the one whose writes all match what is stored now), or with
--ui from System Settings, using the setting's verify spec. Options that couldn't be read are
listed on stderr and left out, which leaves them unmanaged.

--snapshots D   Capture snapshot options (menu bar layout, wallpaper) into D/<option name>.
--only P        Only options whose path starts with P.

capture saves the state arranged in System Settings for one snapshot option, one XML plist per
storage entry, and prints the line to put in your configuration.
"""

from __future__ import annotations

import argparse
import functools
import json
import os
import plistlib
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = Path(os.environ.get("NIX_PLIST_MANAGER_ROOT") or HERE.parent)
UNREAD = object()


def load_options() -> list[dict]:
	result = subprocess.run(["nix", "eval", "--json", f"path:{ROOT}#optionIndex"], capture_output=True, text=True)
	if result.returncode != 0:
		sys.exit(f"nix eval .#optionIndex failed:\n{result.stderr}")
	return json.loads(result.stdout)


@functools.cache
def export(domain: str, by_host: bool = False, system: bool = False) -> dict:
	if system and not domain.startswith("/"):
		domain = f"/Library/Preferences/{domain}"
	elif domain.startswith("~/"):
		domain = str(Path.home() / domain[2:])
	host = ["-currentHost"] if by_host else []
	result = subprocess.run(["defaults", *host, "export", domain, "-"], capture_output=True)
	try:
		return plistlib.loads(result.stdout) if result.returncode == 0 and result.stdout else {}
	except Exception:
		return {}


def stored(key: dict):
	return export(key["domain"], key.get("byHost", False), key.get("scope") == "system").get(key["key"])


# --- a fixed set of values: the one whose writes all match -----------------------------------

def same(actual, expected) -> bool:
	if actual is None:
		return False
	if isinstance(expected, bool) or isinstance(actual, bool):
		return bool(actual) == bool(expected) and not isinstance(actual, (str, dict, list))
	if isinstance(expected, (int, float)) and isinstance(actual, (int, float)):
		return abs(actual - expected) < 1e-6
	if isinstance(expected, dict) and isinstance(actual, dict):
		return set(expected) == set(actual) and all(same(actual[k], v) for k, v in expected.items())
	if isinstance(expected, list) and isinstance(actual, list):
		return len(expected) == len(actual) and all(same(a, e) for a, e in zip(actual, expected))
	return actual == expected


def op_matches(op: dict) -> bool:
	kind = op["op"]
	if kind == "write":
		return same(stored(op["key"]), op["value"])
	if kind == "delete":
		return stored(op["key"]) is None
	if kind == "setMembers":
		items = stored(op["key"]) or []
		return all((item in items) == listed for item, listed in op["members"].items())
	if kind == "writeFlags":
		value = stored(op["key"])
		return (op.get("absent", 0) if value is None else int(value)) & op["mask"] == op["bits"]
	if kind == "mergeDict":
		entries = stored(op["key"]) or {}
		# an entry that is only switched off matches one that isn't there
		return all(same(entries.get(k), v) or (entries.get(k) is None and v == {"enabled": False})
			for k, v in op["entries"].items())
	return False


def read_candidates(entry: dict):
	matching = [c for c in entry["candidates"] if c["ops"] and all(op_matches(op) for op in c["ops"])]
	# prefer the choice that writes something over one that only deletes
	matching.sort(key=lambda c: -sum(op["op"] != "delete" for op in c["ops"]))
	return matching[0]["value"] if matching else UNREAD


# --- a setting's own command ----------------------------------------------------------------

def read_command(entry: dict):
	reads = entry["reads"]
	output = subprocess.run(["/bin/bash", "-c", reads["command"]], capture_output=True, text=True).stdout.strip()
	if not output:
		return UNREAD
	if reads.get("values") is not None:
		name = next((name for name, printed in reads["values"].items() if str(printed) == output), None)
		if name is None:
			return UNREAD
		return json.loads(name) if name in ("true", "false") else name
	if entry["kind"] == "string":
		return output
	try:
		return json.loads(output)
	except ValueError:
		return output


# --- the codec's reader ---------------------------------------------------------------------

def glyphs(equivalent: str, names: dict) -> str:
	"""NSUserKeyEquivalents' "@$s" as the options write it, "⇧⌘S"."""
	modifiers = ""
	while equivalent[:1] in names["equivalentModifiers"] and len(equivalent) > 1:
		modifiers += names["equivalentModifiers"][equivalent[0]]
		equivalent = equivalent[1:]
	return "".join(g for g in "⌃⌥⇧⌘" if g in modifiers) + names["equivalentKeys"].get(equivalent, equivalent.upper())


def hot_key(entries, reader: dict):
	"""A symbolic hotkey as the option takes it: false, true (default keys) or "⌘⇧S"."""
	entry = (entries or {}).get(str(reader["hotKey"]))
	if entry is None:
		return UNREAD
	if not entry.get("enabled"):
		return False
	parameters = entry.get("value", {}).get("parameters")
	key = parameters and reader["names"]["keys"].get(str(parameters[1]))
	if not key:
		return True
	modifiers = sorted(reader["names"]["modifiers"].items(), key=lambda item: "⌃⌥⇧⌘".index(item[1]))
	return "".join(glyph for flag, glyph in modifiers if parameters[2] & int(flag)) + key


def services(entries, names: dict):
	"""Services changed in System Settings: false, true, or their keys."""
	if not isinstance(entries, dict):
		return UNREAD
	result = {}
	for service, status in entries.items():
		if not status.get("enabled_services_menu", True) and not status.get("enabled_context_menu", True):
			result[service] = False
		else:
			result[service] = glyphs(status["key_equivalent"], names) if status.get("key_equivalent") else True
	return result


def app_shortcuts(names: dict) -> dict:
	"""App Shortcuts as the option takes them: { app: { "Menu->Item": "⌘⇧S" } }."""
	result = {}
	for app in export("com.apple.universalaccess").get("com.apple.custommenu.apps") or []:
		items = export(app).get("NSUserKeyEquivalents") or {}
		shortcuts = {"->".join(p for p in title.split("\x1b") if p): glyphs(e, names) for title, e in items.items()}
		if shortcuts:
			result["All Applications" if app == "NSGlobalDomain" else app] = shortcuts
	return result


def app_languages() -> dict:
	"""Installed apps with their own AppleLanguages; some system services keep a copy of the
	global list, which Language & Region doesn't show."""
	home = Path.home()
	files = list((home / "Library/Preferences").glob("*.plist"))
	files += [p for p in home.glob("Library/Containers/*/Data/Library/Preferences/*.plist") if p.stem == p.parts[-5]]
	found = {}
	for path in files:
		try:
			languages = plistlib.loads(path.read_bytes()).get("AppleLanguages")
		except Exception:
			continue
		if not isinstance(languages, list) or path.stem.startswith("."):
			continue
		apps = subprocess.run(["mdfind", f"kMDItemCFBundleIdentifier == '{path.stem}'"], capture_output=True, text=True).stdout
		if any(line.endswith(".app") for line in apps.splitlines()):
			found[path.stem] = languages
	return found


def shared_folders() -> dict:
	folders, name = {}, None
	for line in subprocess.run(["sharing", "-l"], capture_output=True, text=True).stdout.splitlines():
		if line.startswith("name:"):
			name = line.split(":", 1)[1].strip()
		elif line.startswith("path:") and name is not None:
			folders[line.split(":", 1)[1].strip()] = name
	return folders


def read_codec(entry: dict):
	reader = entry["read"]
	value = stored(entry["storage"][0]) if entry["storage"] and entry["storage"][0]["key"] else None
	if reader.get("direct"):
		if value is None:
			return UNREAD
		if entry["kind"] == "number" and isinstance(value, float) and value.is_integer() and "integer" in entry["type"]:
			return int(value)
		return "Use System Language" if value == "__com.apple.AXSettingRecord.nilSentinel__" else value
	if "flags" in reader:
		bits = reader["absent"] if value is None else int(value)
		return {name: bool(bits & bit) for name, bit in reader["flags"].items()}
	if "dict" in reader:
		if not isinstance(value, dict):
			return UNREAD
		return {name: bool(value[item]) for name, item in reader["dict"].items() if item in value}
	if "members" in reader:
		return {name: (item in (value or [])) == reader["listedWhen"] for name, item in reader["members"].items()}
	if "hotKey" in reader:
		return hot_key(value, reader)
	if reader.get("services"):
		return services(value, reader["names"])
	if reader.get("appShortcuts"):
		return app_shortcuts(reader["names"])
	if reader.get("appLanguages"):
		return app_languages()
	if reader.get("sharedFolders"):
		return shared_folders()
	return UNREAD


def read_ui(entry: dict):
	sys.path.insert(0, str(HERE))
	import verify  # noqa: E402
	return verify.shown_values([entry]).get(entry["option"], UNREAD)


def read(entry: dict, use_ui: bool):
	readers = [
		(entry.get("reads"), read_command),
		(entry.get("read"), read_codec),
		(entry.get("candidates"), read_candidates),
		(use_ui and entry.get("verify"), read_ui),
	]
	for applies, reader in readers:
		if not applies:
			continue
		try:
			value = reader(entry)
		except Exception as error:
			print(f"  {entry['option']}: {error}", file=sys.stderr)
			continue
		if value is not UNREAD:
			return value
	return UNREAD


# --- snapshots ------------------------------------------------------------------------------

def capture(entry: dict, directory: Path):
	directory.mkdir(parents=True, exist_ok=True)
	export.cache_clear()
	for storage in entry["storage"]:
		values = export(storage["domain"], storage.get("byHost", False))
		if storage["key"] is not None:
			values = {storage["key"]: values[storage["key"]]} if storage["key"] in values else {}
		path = directory / f"{storage['as']}.plist"
		path.write_bytes(plistlib.dumps(values, fmt=plistlib.FMT_XML, sort_keys=True))
		print(f"wrote {path} ({len(values)} keys)", file=sys.stderr)


def cmd_capture(option: str, directory: Path):
	entry = next((o for o in load_options() if o["option"] == option), None)
	if entry is None:
		sys.exit(f"no option {option}")
	if entry["kind"] != "snapshot":
		sys.exit(f"{option} isn't a snapshot setting; set it in your configuration instead")
	capture(entry, directory)
	relative = os.path.relpath(directory)
	path = f"./{relative}" if not relative.startswith("..") else str(directory.resolve())
	print(f"programs.nix-plist-manager.options.{option} = {path};")


# --- Nix output -----------------------------------------------------------------------------

def nix_value(value, indent: str = "") -> str:
	if isinstance(value, bool):
		return "true" if value else "false"
	if isinstance(value, (int, float)):
		return repr(value)
	if isinstance(value, Path):
		return str(value)
	if isinstance(value, str):
		return json.dumps(value, ensure_ascii=False).replace("${", "\\${")
	if isinstance(value, list):
		return "[ " + " ".join(nix_value(v, indent) for v in value) + " ]"
	inner = indent + "  "
	name = lambda k: k if re.match(r"^[A-Za-z_][A-Za-z0-9_'-]*$", k) else json.dumps(k)
	return "{\n" + "\n".join(f"{inner}{name(k)} = {nix_value(v, inner)};" for k, v in value.items()) + f"\n{indent}}}"


def nest(values: dict[str, object]) -> dict:
	tree: dict = {}
	for path, value in sorted(values.items()):
		*parents, last = path.split(".")
		node = tree
		for part in parents:
			node = node.setdefault(part, {})
		node[last] = value
	return tree


def main():
	if sys.argv[1:2] == ["capture"]:
		if len(sys.argv) != 4:
			sys.exit(__doc__.strip())
		return cmd_capture(sys.argv[2], Path(sys.argv[3]))

	parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
	parser.add_argument("--ui", action="store_true")
	parser.add_argument("--snapshots")
	parser.add_argument("--only", default="")
	args = parser.parse_args()

	results = {"home-manager": {}, "darwin": {}}
	unread = []
	for entry in load_options():
		if not entry["option"].startswith(args.only):
			continue
		if entry["kind"] == "snapshot":
			if not args.snapshots:
				unread.append((entry["option"], "snapshot: pass --snapshots <directory>"))
				continue
			directory = Path(args.snapshots).resolve() / entry["option"].rsplit(".", 1)[1]
			capture(entry, directory)
			results[entry["module"]][entry["option"]] = directory
			continue
		value = read(entry, args.ui)
		if value is UNREAD:
			unread.append((entry["option"], "no value stored" + ("" if args.ui or not entry.get("verify") else " (try --ui)")))
			continue
		results[entry["module"]][entry["option"]] = value
		print(f"  {entry['option']} = {json.dumps(value, ensure_ascii=False)}", file=sys.stderr)

	for module, values in results.items():
		print(f"# {module}: {len(values)} options")
		print(f"programs.nix-plist-manager.options = {nix_value(nest(values))};\n")
	if unread:
		print(f"\nnot read ({len(unread)}):", file=sys.stderr)
		for option, reason in unread:
			print(f"  {option}: {reason}", file=sys.stderr)


if __name__ == "__main__":
	main()
