#!/usr/bin/env python3
"""
current — write this Mac's current settings as nix-plist-manager options.

    nix run .#current -- [--ui] [--snapshots <directory>] [--only <prefix>]

Prints two Nix attribute sets, one for home-manager and one for nix-darwin, with every option
whose value could be read. Values are read from the preferences each option writes: for a
setting with a fixed set of values, the one whose writes all match what is stored now.

--ui            Also read settings that can't be read from preferences (applied through a
                command, or with nothing stored yet) from System Settings, using their verify
                spec. Opens System Settings; needs Accessibility permission.
--snapshots D   Capture snapshot options (menu bar layout, wallpaper) into D/<option name>.
--only P        Only options whose path starts with P.

Options that couldn't be read are listed on stderr; they are left out, which leaves them
unmanaged.
"""

from __future__ import annotations

import argparse
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


# ---------------------------------------------------------------------------
# Reading preferences
# ---------------------------------------------------------------------------

_domains: dict = {}


def domain_path(domain: str, scope: str) -> str:
	if scope == "system":
		return f"/Library/Preferences/{domain}"
	if domain.startswith("~/"):
		return str(Path.home() / domain[2:])
	return domain


def export(domain: str, by_host: bool, scope: str = "user") -> dict:
	cache_key = (domain, by_host, scope)
	if cache_key not in _domains:
		host = ["-currentHost"] if by_host else []
		result = subprocess.run(["defaults", *host, "export", domain_path(domain, scope), "-"], capture_output=True)
		try:
			_domains[cache_key] = plistlib.loads(result.stdout) if result.returncode == 0 and result.stdout else {}
		except Exception:
			_domains[cache_key] = {}
	return _domains[cache_key]


def stored(key: dict):
	"""The value of a storage key, or None when it isn't set."""
	return export(key["domain"], key.get("byHost", False), key.get("scope", "user")).get(key["key"])


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
		value = op.get("absent", 0) if value is None else int(value)
		return value & op["mask"] == op["bits"]
	if kind == "mergeDict":
		entries = stored(op["key"]) or {}
		# an entry that is only switched off matches one that isn't there
		return all(same(entries.get(k), v) or (entries.get(k) is None and v == {"enabled": False})
			for k, v in op["entries"].items())
	return False


# ---------------------------------------------------------------------------
# Reading options
# ---------------------------------------------------------------------------

def read_candidates(entry: dict):
	matching = [c for c in entry["candidates"] if c["ops"] and all(op_matches(op) for op in c["ops"])]
	if not matching:
		return UNREAD
	# prefer the choice that writes something over one that only deletes
	matching.sort(key=lambda c: -sum(op["op"] != "delete" for op in c["ops"]))
	return matching[0]["value"]


def read_with(entry: dict):
	reader = entry["read"]
	key = entry["storage"][0] if entry.get("storage") else None
	if reader.get("direct"):
		value = stored(key)
		if value is None:
			return UNREAD
		if entry["kind"] == "number" and isinstance(value, float) and value.is_integer() and "integer" in entry["type"]:
			value = int(value)
		if isinstance(value, str) and value == "__com.apple.AXSettingRecord.nilSentinel__":
			value = "Use System Language"
		return value
	if "flags" in reader:
		value = stored(key)
		value = reader["absent"] if value is None else int(value)
		return {name: bool(value & bit) for name, bit in reader["flags"].items()}
	if "dict" in reader:
		entries = stored(key)
		if not isinstance(entries, dict):
			return UNREAD
		return {name: bool(entries[item]) for name, item in reader["dict"].items() if item in entries}
	if "members" in reader:
		items = stored(key) or []
		return {name: (item in items) == reader["listedWhen"] for name, item in reader["members"].items()}
	if reader.get("sharedFolders"):
		folders, name = {}, None
		for line in subprocess.run(["sharing", "-l"], capture_output=True, text=True).stdout.splitlines():
			if line.startswith("name:"):
				name = line.split(":", 1)[1].strip()
			elif line.startswith("path:") and name is not None:
				folders[line.split(":", 1)[1].strip()] = name
		return folders
	if reader.get("appLanguages"):
		return app_languages()
	return UNREAD


def app_languages() -> dict:
	"""Apps with their own AppleLanguages, as the Applications list of Language & Region shows
	them: installed apps only, since some system services keep a copy of the global list."""
	home = Path.home()
	files = list((home / "Library/Preferences").glob("*.plist"))
	files += list(home.glob("Library/Containers/*/Data/Library/Preferences/*.plist"))
	found = {}
	for path in files:
		identifier = path.stem
		if identifier.startswith(".") or (path.parent.parent.parent.parent.name not in ("", identifier)
				and "Containers" in path.parts and path.parts[path.parts.index("Containers") + 1] != identifier):
			continue
		try:
			with open(path, "rb") as f:
				languages = plistlib.load(f).get("AppleLanguages")
		except Exception:
			continue
		if not isinstance(languages, list):
			continue
		apps = subprocess.run(["mdfind", f"kMDItemCFBundleIdentifier == '{identifier}'"], capture_output=True, text=True).stdout
		if any(line.endswith(".app") for line in apps.splitlines()):
			found[identifier] = languages
	return found


LEGACY_WRITE = re.compile(
	r"defaults (?:-currentHost )?write (\S+) (?:\"([^\"]+)\"|'([^']+)'|(\S+)) -(\w+) (?:\"([^\"]*)\"|'([^']*)'|(\S+))"
)


def legacy_key(domain: str) -> tuple[str, bool]:
	domain = domain.replace("$HOME/Library/Preferences/", "")
	if domain.startswith("ByHost/"):
		return domain[len("ByHost/"):], True
	return ("NSGlobalDomain" if domain == ".GlobalPreferences" else domain), False


def parse_plist_value(kind: str, text: str):
	if kind == "bool":
		return text in ("true", "YES", "1")
	if kind == "int":
		return int(text)
	if kind == "float":
		return float(text)
	return text


def read_legacy(entry: dict):
	for choice, command in entry["commands"].items():
		if choice == "unset":
			continue
		match = LEGACY_WRITE.search(command)
		if not match:
			continue
		domain, by_host = legacy_key(match.group(1))
		name = match.group(2) or match.group(3) or match.group(4)
		kind = match.group(5)
		text = match.group(6) if match.group(6) is not None else (match.group(7) if match.group(7) is not None else match.group(8))
		# the key in effect: a ByHost copy shadows the plain one
		actual = export(domain, True).get(name) if by_host else None
		if actual is None:
			actual = export(domain, False).get(name)
		if choice == "value":
			return UNREAD if actual is None else actual
		if actual is not None and same(actual, parse_plist_value(kind, text)):
			return choice == "true" if choice in ("true", "false") else choice
	return UNREAD


def read_pmset(entry: dict):
	"""Battery settings applied through pmset: read `pmset -g custom`."""
	output = subprocess.run(["pmset", "-g", "custom"], capture_output=True, text=True).stdout
	sections, current = {}, None
	for line in output.splitlines():
		if line.endswith(":") and not line.startswith(" "):
			current = sections.setdefault(line[:-1].strip(), {})
		elif current is not None and line.strip():
			parts = line.split()
			current[parts[0]] = parts[-1]
	battery, ac = sections.get("Battery Power", {}), sections.get("AC Power", {})
	option = entry["option"]
	modes = {"0": "Automatic", "1": "Low Power", "2": "High Power"}
	if option.endswith("energyMode.onBattery"):
		return modes.get(battery.get("powermode"), UNREAD)
	if option.endswith("energyMode.onPowerAdapter"):
		return modes.get(ac.get("powermode"), UNREAD)
	if option.endswith("slightlyDimTheDisplayOnBattery") and "lessbright" in battery:
		return battery["lessbright"] == "1"
	if option.endswith("preventAutomaticSleepingOnPowerAdapterWhenTheDisplayIsOff") and "sleep" in ac:
		return ac["sleep"] == "0"
	if option.endswith("wakeForNetworkAccess") and "womp" in ac:
		if battery.get("womp") == "1":
			return "Always"
		return "Only on Power Adapter" if ac["womp"] == "1" else "Never"
	return UNREAD


def read_sharing(option: str):
	disabled = subprocess.run(["launchctl", "print-disabled", "system"], capture_output=True, text=True).stdout
	daemons = {"fileSharing": "com.apple.smbd", "screenSharing": "com.apple.screensharing",
		"remoteApplicationScripting": "com.apple.AEServer"}
	name = option.rsplit(".", 1)[1]
	if name in daemons:
		return f'"{daemons[name]}" => enabled' in disabled
	if name == "printerSharing":
		return "_share_printers=1" in subprocess.run(["cupsctl"], capture_output=True, text=True).stdout
	if name == "contentCaching":
		return bool(export("com.apple.AssetCache", False, "system").get("Activated"))
	groups = {"screenSharingOptions": "com.apple.access_screensharing",
		"remoteApplicationScriptingOptions": "com.apple.access_remote_ae"}
	parent = option.rsplit(".", 2)[1]
	if name == "allowAccessFor" and parent in groups:
		exists = subprocess.run(["dscl", ".", "-read", f"/Groups/{groups[parent]}"], capture_output=True).returncode == 0
		return "Only these users" if exists else "All users"
	if name == "remoteManagement":
		return bool(subprocess.run(["pgrep", "-x", "ARDAgent"], capture_output=True).stdout)
	return UNREAD


def read_special(entry: dict):
	option = entry["option"]
	if ".battery." in option:
		return read_pmset(entry)
	if option.endswith("dateAndTime.timeZone"):
		target = os.readlink("/etc/localtime")
		return target.split("zoneinfo/", 1)[1] if "zoneinfo/" in target else UNREAD
	if ".general.sharing." in option:
		return read_sharing(option)
	if option.endswith("dateAndTime.source"):
		for line in Path("/etc/ntp.conf").read_text().splitlines():
			if line.startswith("server "):
				return line.split()[1]
	return UNREAD


def read_ui(entry: dict):
	sys.path.insert(0, str(ROOT / "tools" / "verify"))
	import verify  # noqa: E402
	value = verify.current_value(entry["verify"])
	return UNREAD if value is verify.NOTHING else value


def read(entry: dict, use_ui: bool):
	value = UNREAD
	if entry["kind"] == "legacy":
		value = read_legacy(entry)
	else:
		if entry.get("read"):
			value = read_with(entry)
		if value is UNREAD and entry.get("appliedThroughCommand"):
			value = read_special(entry)
		if value is UNREAD and entry.get("candidates"):
			value = read_candidates(entry)
	if value is UNREAD and use_ui and entry.get("verify"):
		try:
			value = read_ui(entry)
		except Exception as error:
			print(f"  {entry['option']}: reading System Settings failed: {error}", file=sys.stderr)
	return value


# ---------------------------------------------------------------------------
# Nix output
# ---------------------------------------------------------------------------

IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_'-]*$")


def nix_name(name: str) -> str:
	return name if IDENTIFIER.match(name) else json.dumps(name)


def nix_value(value, indent: str) -> str:
	if isinstance(value, bool):
		return "true" if value else "false"
	if isinstance(value, (int, float)):
		return repr(value)
	if isinstance(value, str):
		if value.startswith("/") and value.endswith("#path"):
			return value[: -len("#path")]
		return json.dumps(value, ensure_ascii=False).replace("${", "\\${")
	if isinstance(value, list):
		return "[ " + " ".join(nix_value(v, indent) for v in value) + " ]"
	if isinstance(value, dict):
		inner = indent + "  "
		lines = [f"{inner}{nix_name(k)} = {nix_value(v, inner)};" for k, v in value.items()]
		return "{\n" + "\n".join(lines) + f"\n{indent}}}"
	raise TypeError(value)


def nest(values: dict[str, object]) -> dict:
	tree: dict = {}
	for path, value in sorted(values.items()):
		node = tree
		parts = path.split(".")
		for part in parts[:-1]:
			node = node.setdefault(part, {})
		node[parts[-1]] = value
	return tree


def main():
	parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
	parser.add_argument("--ui", action="store_true")
	parser.add_argument("--snapshots")
	parser.add_argument("--only", default="")
	args = parser.parse_args()

	index = json.loads(subprocess.run(
		["nix", "eval", "--json", f"path:{ROOT}#optionIndex"], check=True, capture_output=True, text=True
	).stdout)

	results = {"home-manager": {}, "darwin": {}}
	unread = []
	for entry in index:
		if not entry["option"].startswith(args.only):
			continue
		if entry["kind"] == "snapshot":
			if not args.snapshots:
				unread.append((entry["option"], "snapshot: pass --snapshots <directory>"))
				continue
			directory = Path(args.snapshots).resolve() / entry["option"].rsplit(".", 1)[1]
			subprocess.run([sys.executable, str(ROOT / "tools" / "capture.py"), entry["option"], str(directory)],
				check=True, stdout=subprocess.DEVNULL)
			results[entry["module"]][entry["option"]] = f"{directory}#path"
			continue
		value = read(entry, args.ui)
		if value is UNREAD:
			unread.append((entry["option"], "no value stored" if not entry.get("verify") or args.ui else "no value stored (try --ui)"))
			continue
		results[entry["module"]][entry["option"]] = value
		print(f"  {entry['option']} = {json.dumps(value, ensure_ascii=False)}", file=sys.stderr)

	for module, values in results.items():
		prefix = "programs.nix-plist-manager.options"
		print(f"# {module}: {len(values)} options")
		print(f"{prefix} = {nix_value(nest(values), '')};\n")
	if unread:
		print(f"\nnot read ({len(unread)}):", file=sys.stderr)
		for option, reason in unread:
			print(f"  {option}: {reason}", file=sys.stderr)


if __name__ == "__main__":
	main()
