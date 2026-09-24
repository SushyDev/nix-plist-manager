#!/usr/bin/env python3
"""
verify — round-trip testing of options against the real System Settings UI.

Commands:
    controls <pane>                 List the labelled controls a pane shows, with their values.
    observe <pane> <ax command…>    Operate a control through Accessibility and print which
                                    preferences changed, e.g. `observe <pane> press "Magnification"`.
    discover <pane> <inventory file>
                                    Add the settings a pane shows to the inventory (`ui:` sources).
    probe <pane> [--open …] [--skip regex] [--out file]
                                    Operate every checkbox, pop-up and radio button in a pane and
                                    record which preferences each choice writes, putting it back.
    apply <option> <json value>     Run the command an option generates for a value.
    check [--pane P] [--setting S]  For every inventory setting whose option has a `verify` spec:
                                    back up the keys it stores, apply each value in the spec,
                                    reopen System Settings and compare the controls against the
                                    spec, then restore the backup. Passing settings get `verified`.

<pane> is the identifier of the pane's sidebar item, e.g. com.apple.settings.appearance
(`ax dump` lists them).

`check` reads the spec from the setting's `verify` field in Nix (see lib/settings/setting.nix):

    verify = {
      pane = "com.apple.settings.appearance";
      open = [ "Hot Corners…" ];                     # optional: controls to press first
      operate = [ "click" "TintWindowBackgroundToggle" ];  # optional, see below
      expect = {
        true = { TintWindowBackgroundToggle = 1; };
        false = { TintWindowBackgroundToggle = 0; };
      };
    };

`expect` maps each value (as the option spells it) to control labels (in `ax` label syntax)
and the expected AXValue, or { selected = true; } for buttons that only show selection.

`operate` is an ax command that flips the control in the UI, twice, and fails unless that
changes the keys the option writes. For controls that don't toggle, give the action there and
the one back: [ [ "press" "A" ] [ "press" "B" ] ].

`check` finds the value System Settings shows before it starts and applies it again at the end,
so order doesn't matter, but include the values people are likely to have.

Requires Accessibility permission. ax.swift is compiled on first use.
"""

from __future__ import annotations

import argparse
import datetime
import json
import os
import plistlib
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = Path(os.environ.get("NIX_PLIST_MANAGER_ROOT") or HERE.parents[1])
sys.path.insert(0, str(ROOT / "tools" / "inventory"))
import inventory  # noqa: E402

CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "nix-plist-manager"
AX_BINARY = CACHE / "ax"

HOME = Path.home()
PREFERENCE_DIRS = [
	HOME / "Library/Preferences",
	HOME / "Library/Preferences/ByHost",
	Path("/Library/Preferences"),
]
CONTAINER_GLOBS = [
	"Library/Containers/*/Data/Library/Preferences",
	"Library/Group Containers/*/Library/Preferences",
]

# preferences that change on their own and would drown out real changes
NOISE = re.compile(
	r"(LastUpdate|Timestamp|LastSeen|lastUsed|LaunchCount|WindowFrame|NSWindow|NSSplitView|"
	r"NSNavPanel|NSToolbar|NSStatusItem Preferred Position|MRU|Recent|History|Session|"
	r"LastReloaded|Workaround_)",
	re.IGNORECASE,
)
NOISY_DOMAINS = {
	"com.apple.systempreferences", "com.apple.Settings", "com.apple.cfprefsd.daemon",
	"com.apple.systemsettings.extensions", "com.apple.spaces", "com.apple.CloudKit",
	"com.apple.xpc.activity2", "ContextStoreAgent", "com.apple.knowledge-agent",
	"com.apple.suggestions", "com.apple.appleaccount", "com.apple.ncprefs.cache",
	"com.apple.configurationprofiles.user", "com.apple.siri.shortcuts", "com.apple.spotlightknowledged.pipeline",
	"com.apple.lighthouse.pnr.PnROnDeviceWorker", "com.apple.siri.analytics.assistant",
	"com.apple.siri.ODDI.MetricsWorker", "com.apple.unilog.MacMailSearch", "com.apple.biometrickitd",
	"com.apple.icloud.searchpartyuseragent", "com.apple.powerlogd", "com.apple.analyticsagent",
	"com.apple.systemsettingsagent", "com.apple.routined", "com.apple.bird.containers.notifications",
	"com.apple.fileproviderd", "com.apple.campo", "com.apple.photolibraryd", "com.creative.ios.creativeapp",
}


# ---------------------------------------------------------------------------
# Accessibility
# ---------------------------------------------------------------------------

def ax(*args: str, check: bool = True) -> str:
	source = HERE / "ax.swift"
	if not AX_BINARY.exists() or AX_BINARY.stat().st_mtime < source.stat().st_mtime:
		CACHE.mkdir(parents=True, exist_ok=True)
		subprocess.run(["swiftc", "-O", str(source), "-o", str(AX_BINARY)], check=True)
	result = subprocess.run([str(AX_BINARY), *args], capture_output=True, text=True)
	if check and result.returncode != 0:
		raise RuntimeError(result.stderr.strip())
	return result.stdout


def open_pane(pane: str, fresh: bool = False, wait_for: str | None = None, steps: list[str] = ()):
	"""Show a pane by pressing its sidebar item. `fresh` quits System Settings first so it
	rereads every preference. (x-apple.systempreferences: URLs sometimes land on the wrong pane.)"""
	if fresh:
		subprocess.run(["killall", "System Settings"], capture_output=True)
		time.sleep(1)
	subprocess.run(["open", "-b", "com.apple.systempreferences"], check=True)
	# rows further down the sidebar only exist once scrolled to: click scrolls them into view
	def show():
		try:
			return ax("press", pane)
		except RuntimeError:
			return ax("click", pane)
	wait_until(show, f"sidebar item {pane}")
	for step in steps:
		# "click:<label>" clicks instead, for list rows that ignore AXPress (Keyboard Shortcuts…'s categories)
		action, target = ("click", step.removeprefix("click:")) if step.startswith("click:") else ("press", step)
		wait_until(lambda: ax(action, target), step)
		time.sleep(0.5)
	if wait_for:
		wait_until(lambda: ax("get", wait_for), wait_for)


def wait_until(attempt, what: str, timeout: float = 15):
	deadline = time.time() + timeout
	while True:
		try:
			return attempt()
		except RuntimeError:
			if time.time() > deadline:
				raise RuntimeError(f"timed out waiting for {what}")
			time.sleep(0.5)


def controls(pane: str) -> list[dict]:
	open_pane(pane)
	time.sleep(1)
	entries = [json.loads(line) for line in ax("dump").splitlines()]
	# skip the sidebar and window chrome, keep things a user can change
	interesting = {"AXCheckBox", "AXRadioButton", "AXPopUpButton", "AXSlider", "AXButton", "AXTextField", "AXMenuButton"}
	return [
		e for e in entries
		if e["role"] in interesting and e.get("labels")
		and "Sidebar" not in e.get("path", [])
		and not any(l.startswith("com.apple.settings.") for l in e["labels"])
	]


# ---------------------------------------------------------------------------
# Preference snapshots
# ---------------------------------------------------------------------------

_files: list[Path] | None = None


def preference_files() -> list[Path]:
	"""Every preference file, listed once per run: listing the containers is slow."""
	global _files
	if _files is None:
		dirs = list(PREFERENCE_DIRS)
		for pattern in CONTAINER_GLOBS:
			dirs += HOME.glob(pattern)
		_files = []
		for directory in dirs:
			try:
				# not glob("*.plist"): that skips .GlobalPreferences.plist
				_files += [directory / name for name in os.listdir(directory) if name.endswith(".plist")]
			except OSError:  # sandboxed containers can refuse, or the call gets interrupted
				pass
	# files created since are found in the directories themselves
	for directory in PREFERENCE_DIRS:
		try:
			_files += [directory / name for name in os.listdir(directory)
				if name.endswith(".plist") and directory / name not in _files]
		except OSError:
			pass
	return _files


def read_plist(path: Path):
	try:
		with open(path, "rb") as f:
			return plistlib.load(f)
	except Exception:
		return None


_contents: dict[Path, tuple[float, object]] = {}


def cached_plist(path: Path, mtime: float):
	"""A preference file's contents, read again only when its modification time changed."""
	cached = _contents.get(path)
	if cached is None or cached[0] != mtime:
		cached = (mtime, read_plist(path))
		_contents[path] = cached
	return cached[1]


def snapshot() -> dict[Path, tuple[float, object]]:
	result = {}
	for path in preference_files():
		try:
			result[path] = (path.stat().st_mtime, None)
		except OSError:
			pass
	return result


def load_changed(before: dict, after: dict) -> list[Path]:
	return [p for p, (mtime, _) in after.items() if p not in before or before[p][0] != mtime]


def diff_values(old, new, prefix: str = "") -> list[tuple[str, object, object]]:
	if isinstance(old, dict) and isinstance(new, dict):
		changes = []
		for key in sorted(set(old) | set(new), key=str):
			changes += diff_values(old.get(key), new.get(key), f"{prefix}.{key}" if prefix else str(key))
		return changes
	return [] if old == new else [(prefix, old, new)]


def domain_of(path: Path) -> str:
	name = re.sub(r"\.[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}$", "", path.stem, flags=re.IGNORECASE)
	return ("ByHost " if "/ByHost/" in str(path) else "") + name


def settle(quiet: float = 1.0, timeout: float = 20):
	"""Wait for pending preference writes to reach disk, so a snapshot isn't stale."""
	last, quiet_since, deadline = snapshot(), time.time(), time.time() + timeout
	while time.time() - quiet_since < quiet and time.time() < deadline:
		time.sleep(0.5)
		now = snapshot()
		if load_changed(last, now):
			quiet_since = time.time()
		last = now


def observe(action) -> list[tuple[str, str, object, object]]:
	"""Run `action` and return (domain, key path, old, new) for every preference it changed."""
	settle()
	before = snapshot()
	contents = {p: cached_plist(p, mtime) for p, (mtime, _) in before.items()}
	action()

	# cfprefsd flushes to disk seconds after the change; wait for the first write (a control
	# that writes nothing gives up after a few seconds), then until nothing changes for a moment
	changed, quiet_since, first_deadline = set(), None, time.time() + 4
	while (quiet_since is None and time.time() < first_deadline) or (quiet_since is not None and time.time() - quiet_since < 1.2):
		time.sleep(0.3)
		now = snapshot()
		new = set(load_changed(before, now)) - changed
		if new:
			changed |= new
			quiet_since = time.time()

	results = []
	for path in sorted(changed):
		domain = domain_of(path)
		if domain.split(" ")[-1] in NOISY_DOMAINS:
			continue
		for key, old, new in diff_values(contents.get(path) or {}, read_plist(path) or {}):
			if not NOISE.search(key):
				results.append((domain, key, old, new))
	return results


# ---------------------------------------------------------------------------
# Options
# ---------------------------------------------------------------------------

def command_for(option: str, value) -> str:
	expr = f'f: f {json.dumps(option)} (builtins.fromJSON {json.dumps(json.dumps(value))})'
	result = subprocess.run(
		["nix", "eval", "--raw", f"path:{ROOT}#lib.commandFor", "--apply", expr],
		capture_output=True, text=True,
	)
	if result.returncode != 0:
		raise RuntimeError(result.stderr.strip().splitlines()[-1])
	return result.stdout


def apply(option: str, value):
	command = command_for(option, value)
	subprocess.run(["/bin/bash", "-c", command], check=True)


def storage_values(storage: list[dict]) -> dict:
	values = {}
	for entry in storage:
		host = ["-currentHost"] if entry.get("byHost") else []
		result = subprocess.run(["defaults", *host, "export", entry["domain"], "-"], capture_output=True)
		domain = plistlib.loads(result.stdout) if result.returncode == 0 and result.stdout else {}
		values[(entry["domain"], entry["key"], bool(entry.get("byHost")))] = domain.get(entry["key"])
	return values


def restore_values(values: dict):
	"""Put each key back exactly as it was, leaving the rest of its domain alone.
	`defaults import` merges, so importing a one-key plist restores just that key."""
	for (domain, key, by_host), value in values.items():
		host = ["-currentHost"] if by_host else []
		if value is None:
			subprocess.run(["defaults", *host, "delete", domain, key], capture_output=True)
			continue
		fd, path = tempfile.mkstemp(suffix=".plist")
		with os.fdopen(fd, "wb") as f:
			plistlib.dump({key: value}, f)
		subprocess.run(["defaults", *host, "import", domain, path], check=True)
		os.unlink(path)


def matches(actual: dict, expected) -> bool:
	if isinstance(expected, dict):
		return all(bool(actual.get(k)) == v if isinstance(v, bool) else actual.get(k) == v for k, v in expected.items())
	value = actual.get("value")
	if isinstance(expected, (int, float)) and isinstance(value, (int, float)):
		return abs(value - expected) < 1e-6
	if isinstance(expected, str) and isinstance(value, str):
		return value.strip() == expected.strip()  # some menus pad their titles
	return value == expected


def check_ui_writes(spec: dict, option: dict) -> list[str]:
	"""Operate the control in System Settings, there and back, and make sure that changes the keys
	the option writes. If it doesn't, the option writes somewhere System Settings doesn't look
	(e.g. a ByHost domain that shadows the one it uses) or the spec operates the wrong control."""
	storage = storage_of(option)
	operate = spec["operate"]
	# a toggle is operated twice; radio buttons and pickers need an action there and one back
	there_action, back_action = operate if isinstance(operate[0], list) else (operate, operate)
	open_pane(spec["pane"], fresh=True, wait_for=there_action[1], steps=spec["open"])
	time.sleep(1)
	if back_action != there_action:
		ax(*back_action)  # start from the "back" state, whatever the last applied value was
		time.sleep(1.5)

	# read through cfprefsd rather than the plist files, which are written seconds later
	before = storage_values(storage)
	ax(*there_action)
	time.sleep(1.5)
	there = storage_values(storage)
	ax(*back_action)
	time.sleep(1.5)
	back = storage_values(storage)

	# the key has to move and move back; "back" may be an equivalent value (e.g. System Settings
	# deletes a key the option writes as false)
	if any(there[key] != before[key] and back[key] != there[key] for key in before):
		return []
	return [
		f"operating {there_action} in System Settings doesn't change what the option writes "
		f"({', '.join(k for _, k, _ in before)}); does the option write a domain that shadows the one "
		"System Settings uses?"
	]


def expectations_met(expectations: dict) -> list[str]:
	failures = []
	for control, expected in expectations.items():
		try:
			actual = json.loads(ax("get", control))
		except RuntimeError as error:
			failures.append(f"{control}: {error}")
			continue
		if not matches(actual, expected):
			shown = {k: actual.get(k) for k in ("value", "selected") if k in actual}
			failures.append(f"{control}: expected {expected}, got {shown}")
	return failures


NOTHING = object()


def current_value(spec: dict):
	"""The spec value System Settings shows right now, so it can be put back afterwards."""
	try:
		open_pane(spec["pane"], fresh=True, steps=spec["open"])
	except RuntimeError:
		# the page only exists for some values (e.g. a list of the apps that have shortcuts)
		return NOTHING
	time.sleep(1)
	for case in spec["expect"]:
		if not expectations_met(case["controls"]):
			return case["value"]
	return NOTHING


def storage_of(entry: dict) -> list[dict]:
	"""Where an option keeps its value: declared for settings, parsed from commands otherwise."""
	return entry.get("storage") or inventory.storage_from_commands(entry["commands"])


def check_setting(data: dict, setting: dict, build: str, entry: dict) -> bool:
	spec, option = entry["verify"], setting["option"]
	label = f"{inventory.pane_label(data)} :: {setting['title']}"
	commands = {json.dumps(case["value"]): command_for(option, case["value"]) for case in spec["expect"]}
	# back up what the option stores, and what the values write besides (settings they imply)
	storage = []
	for key in storage_of(entry) + inventory.storage_from_commands(commands):
		if key.get("scope") != "system" and key not in storage:  # system keys need root
			storage.append(key)
	before = storage_values(storage)
	original = current_value(spec)
	failures, command = [], ""
	try:
		for case in spec["expect"]:
			value, expectations = case["value"], case["controls"]
			command = commands[json.dumps(value)]
			subprocess.run(["/bin/bash", "-c", command], check=True)
			time.sleep(spec.get("settle", 1.5))
			first = next(iter(expectations))
			open_pane(spec["pane"], fresh=True, wait_for=None if spec["open"] else first, steps=spec["open"])
			failures += [f"{json.dumps(value)}: {failure}" for failure in expectations_met(expectations)]
		if spec["operate"]:
			failures += check_ui_writes(spec, entry)
	finally:
		# some options change live state (e.g. dark mode) that restoring preference keys alone
		# doesn't undo, so put the original value back through the option first
		if original is not NOTHING:
			subprocess.run(["/bin/bash", "-c", command_for(option, original)], check=False)
		restore_after_restarting(before, re.findall(r"killall(?: -KILL)? '?([^' \n]+)'?", command) + ["System Settings"])
		after = storage_values(storage)
		for key, value in before.items():
			if after.get(key) != value:
				print(f"RESTORE MISMATCH {key[0]} {key[1]}: was {value!r}, now {after.get(key)!r}")

	if failures:
		setting.pop("verified", None)
		print(f"FAIL {label}")
		for failure in failures:
			print(f"     {failure}")
		return False
	print(f"ok   {label}")
	setting["verified"] = {
		"build": build,
		"date": datetime.date.today().isoformat(),
		"commands": inventory.commands_digest(entry),
	}
	return True


# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------

def is_identifier(label: str) -> bool:
	"""TintWindowBackgroundToggle, auto-hide-dock, position: names for code, not people."""
	return " " not in label and (bool(re.search(r"[a-z][A-Z]|-|_|\.", label)) or label.islower())


def human_label(labels: list[str]) -> str:
	"""The label a person reads. Grouped controls carry their own label and the group's,
	e.g. "On Desktop" in "Show items", which becomes "Show items > On Desktop"."""
	readable = list(dict.fromkeys(l for l in labels if not is_identifier(l)))
	if not readable:
		return labels[0]
	if len(readable) > 1 and labels.index(readable[0]) < labels.index(readable[-1]) - 1:
		return f"{readable[-1]} > {readable[0]}"
	return readable[0]


def discover(pane: str, steps: list[str] = ()) -> list[dict]:
	"""Settings a pane shows, as inventory candidates: switches and checkboxes become bools,
	sliders numbers, pop-ups and groups of selectable buttons enums."""
	open_pane(pane, steps=steps)
	time.sleep(1)
	# `steps` open a sheet or a sub-page; only a sheet's contents are separate from the pane
	try:
		dump = ax("dump", "--sheet") if steps else ax("dump")
	except RuntimeError:
		dump = ax("dump")
	entries = [json.loads(line) for line in dump.splitlines()]
	chrome = {"Go Back", "Go Forward", "Help", "Search"}
	entries = [
		e for e in entries
		if "Sidebar" not in e.get("path", []) and not chrome & set(e.get("labels", []))
	]

	candidates, group, last_text = [], None, None

	def flush():
		nonlocal group
		# a picker, not a row of unrelated buttons: something in it is selected, or its
		# members say which setting they belong to
		if group and (group["labelled"] or any(m.get("selected") or m.get("value") == 1 for m in group["members"])):
			choices = [human_label(m["labels"]) for m in group["members"]]
			title = group["title"]
			if any(c["title"] == title for c in candidates):
				title = f"{title} ({'/'.join(choices)})"
			candidates.append({"title": title, "kind": "enum", "choices": choices})
		group = None

	for entry in entries:
		role, labels = entry["role"], entry.get("labels", [])
		if role == "AXStaticText":
			last_text = entry.get("value")
			continue
		if role in ("AXButton", "AXRadioButton") and labels and not labels[0].endswith("…"):
			# members of one picker share a second label ("Blue | Color") or follow each other
			title = labels[1] if len(labels) > 1 else last_text
			if group is None or group["title"] != title or group["role"] != role:
				flush()
				group = {"title": title, "members": [], "role": role, "labelled": len(labels) > 1}
			group["members"].append(entry)
			continue
		flush()
		if not labels:
			continue
		kind = {"AXCheckBox": "bool", "AXSlider": "number", "AXPopUpButton": "enum"}.get(role)
		if kind:
			choices = []
			if role == "AXPopUpButton" and entry.get("enabled", True):
				for _ in range(3):  # the previous menu may still be closing
					try:
						choices = json.loads(ax("items", " + ".join(labels)))
					except (RuntimeError, ValueError):
						choices = []
					if choices:
						break
					time.sleep(0.5)
			candidates.append({"title": human_label(labels), "kind": kind, "choices": choices})
	flush()
	return [c for c in candidates if c["title"]]


# ---------------------------------------------------------------------------
# Probing: which preferences each control writes
# ---------------------------------------------------------------------------

def plain(value):
	"""A preference value as JSON, keeping blobs and dates readable."""
	if isinstance(value, (bytes, bytearray)):
		return f"<{len(value)} bytes>"
	if isinstance(value, datetime.datetime):
		return value.isoformat()
	if isinstance(value, dict):
		return {str(k): plain(v) for k, v in value.items()}
	if isinstance(value, list):
		return [plain(v) for v in value]
	return value


def value_of(selector: str):
	return json.loads(ax("get", selector)).get("value")


def toggle(selector: str):
	"""Flip a checkbox or switch: AXPress, or a click for SwiftUI switches that ignore it."""
	before = value_of(selector)
	ax("press", selector)
	time.sleep(0.7)
	if value_of(selector) == before:
		ax("click", selector)


def writes(action) -> list[dict]:
	return [
		{"domain": domain, "key": key, "from": plain(old), "to": plain(new)}
		for domain, key, old, new in observe(action)
	]


# consent to share data with Apple: never operated, even to switch it back, since switching it on
# can send data or record consent elsewhere
CONSENT = re.compile(r"improve|analytics|share .*with apple|audio donation|data sharing", re.IGNORECASE)


def probe_entries(entries, skip, max_choices, only=None) -> list[dict]:
	"""Operate every enabled checkbox, pop-up, radio button, slider and stepper among `entries`, record
	what each choice writes, and put each control back."""
	chrome = {"Go Back", "Go Forward", "Help", "Search"}
	entries = [
		e for e in entries
		if e["role"] in ("AXCheckBox", "AXPopUpButton", "AXRadioButton", "AXSlider", "AXIncrementor")
		and e.get("labels") and e.get("enabled", True)
		and "Sidebar" not in e.get("path", []) and not chrome & set(e["labels"])
		and not (skip and re.search(skip, " ".join(e["labels"]), re.IGNORECASE))
		and not CONSENT.search(" ".join(e["labels"]))
	]

	results = []
	for entry in entries:
		if only is not None and (entry["role"], tuple(entry["labels"])) != only:
			continue
		selector = f"{entry['role']}:{' + '.join(entry['labels'])}"
		record = {"control": human_label(entry["labels"]), "labels": entry["labels"], "role": entry["role"]}
		print(f"probing {record['control']}", file=sys.stderr)
		try:
			if entry["role"] == "AXCheckBox":
				record["value"] = entry.get("value")
				record["there"] = writes(lambda: toggle(selector))
				# switching back is only acted, not observed: it says nothing new
				toggle(selector)
				time.sleep(0.5)
				record["back"] = []
				# some switches ignore a click that follows too closely; the user's setting
				# must not stay flipped
				for _ in range(2):
					if value_of(selector) == entry.get("value"):
						break
					time.sleep(1.5)
					if value_of(selector) != entry.get("value"):
						record["back"] += writes(lambda: toggle(selector))
				if value_of(selector) != entry.get("value"):
					record["warning"] = "not restored"
			elif entry["role"] == "AXPopUpButton":
				current = entry.get("value")
				record["value"] = current
				record["choices"] = {}
				items = [i for i in json.loads(ax("items", selector)) if i != current and not i.endswith("…") and i != "-"]
				record["items"] = len(items) + 1
				for item in items[:max_choices]:
					record["choices"][item] = writes(lambda: ax("pick", selector, item))
				if current is not None:
					ax("pick", selector, current)
					record["choices"][current] = []
					# items in submenus (Region: Europe > …) can't be picked back
					if value_of(selector) != current:
						record["warning"] = "not restored"
			elif entry["role"] in ("AXSlider", "AXIncrementor"):
				# one step up and back down (or down and back up at the top)
				record["value"] = entry.get("value")
				record["there"] = writes(lambda: ax("step", selector, "up"))
				direction = ("down", "up")
				if not record["there"]:
					record["there"] = writes(lambda: ax("step", selector, "down"))
					direction = ("up", "down")
				record["back"] = writes(lambda: ax("step", selector, direction[0]))
				if value_of(selector) != entry.get("value"):
					record["warning"] = "not restored"
			elif entry["role"] == "AXRadioButton":
				if entry.get("value") == 1:
					continue  # probed by pressing the others, then put back below
				siblings = [e for e in entries if e["role"] == "AXRadioButton" and e.get("path") == entry.get("path")]
				original = next((e for e in siblings if e.get("value") == 1), None)
				record["there"] = writes(lambda: ax("press", selector))
				if original:
					back = f"AXRadioButton:{' + '.join(original['labels'])}"
					record["back"] = writes(lambda: ax("press", back))
					record["value"] = human_label(original["labels"])
		except RuntimeError as error:
			record["error"] = str(error)
		results.append(record)
	return results


def probe(pane: str, steps: list[str], skip: str | None, max_choices: int | None = None,
		sheets: str | None = None) -> list[dict]:
	"""Probe a pane (or the sheet or sub-page `steps` open), then every sheet behind its (i)
	buttons and behind the buttons whose label matches `sheets`."""
	# a fresh launch, so a sub-page opened earlier doesn't hide the button that opens this one
	open_pane(pane, fresh=bool(steps), steps=steps)
	time.sleep(1)
	try:
		dump = ax("dump", "--sheet") if steps else ax("dump")
	except RuntimeError:
		dump = ax("dump")
	entries = [json.loads(line) for line in dump.splitlines()]
	results = probe_entries(entries, skip, max_choices)

	openers = [
		e for e in entries
		if e["role"] == "AXButton" and e.get("enabled", True) and "Sidebar" not in e.get("path", [])
		and ("Show Detail" in e.get("labels", [])
			or (sheets and e.get("labels") and re.fullmatch(sheets, e["labels"][0])))
	]
	for button in openers:
		selector = f"AXButton:{' + '.join(button['labels'])}"
		name = next((l for l in button["labels"] if l != "Show Detail"), "details")
		print(f"opening {name}", file=sys.stderr)

		def show_sheet():
			open_pane(pane, fresh=bool(steps), steps=steps)
			try:
				ax("press", selector)
			except RuntimeError:
				ax("click", selector)
			time.sleep(1.5)
			return [json.loads(line) for line in ax("dump", "--sheet").splitlines()]

		try:
			sheet = show_sheet()
		except RuntimeError as error:
			results.append({"control": name, "sheet": True, "error": str(error)})
			continue
		# one control at a time from a freshly opened sheet: closing a menu can close the sheet
		controls = [e for e in sheet if e["role"] in ("AXCheckBox", "AXPopUpButton", "AXRadioButton", "AXSlider", "AXIncrementor")]
		for entry in controls:
			try:
				fresh = show_sheet()
			except RuntimeError as error:
				results.append({"control": name, "sheet": True, "error": str(error)})
				break
			only = (entry["role"], tuple(entry.get("labels") or ()))
			for record in probe_entries(fresh, skip, max_choices, only):
				record["sheet"] = name
				results.append(record)
			close_sheet()
	return results


def close_sheet():
	for label in ("Done", "OK", "Cancel", "Close"):
		try:
			ax("press", f"AXButton:{label}")
			time.sleep(0.8)
			return
		except RuntimeError:
			continue


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def cmd_probe(args):
	results = probe(args.pane, args.open or [], args.skip, args.max_choices, args.sheets)
	text = json.dumps(results, indent=1, ensure_ascii=False)
	if args.out:
		Path(args.out).write_text(text)
	else:
		print(text)


def cmd_controls(args):
	for entry in controls(args.pane):
		state = {k: entry[k] for k in ("value", "selected", "enabled") if k in entry}
		print(f"{entry['role']:14} {' | '.join(entry['labels'])}  {json.dumps(state, ensure_ascii=False) if state else ''}")


def cmd_observe(args):
	open_pane(args.pane, fresh=bool(args.open), steps=args.open or [])
	time.sleep(1)
	for domain, key, old, new in observe(lambda: ax(*args.ax)):
		print(f"{domain}  {key}: {short(old)} -> {short(new)}")


def short(value) -> str:
	text = repr(value)
	return text if len(text) <= 100 else text[:97] + "..."


def cmd_apply(args):
	apply(args.option, json.loads(args.value))


def cmd_discover(args):
	candidates = discover(args.pane, args.open or [])
	files = inventory.load_all()
	path = (ROOT / args.inventory).resolve()
	if path not in files:
		sys.exit(f"no inventory file {args.inventory}")
	build = inventory.current_build()
	for candidate in candidates:
		print(f"{candidate['kind']:7} {candidate['title']}" + (f"  {candidate['choices']}" if candidate["choices"] else ""))
		inventory.merge_candidate(files[path], {
			"source": f"ui:{args.pane}/{' > '.join(args.open or [])}{'/' if args.open else ''}{candidate['title']}",
			"section": args.section,
			**candidate,
		}, build)
	inventory.save_all(files)


ACTIVATE_SETTINGS = "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"


def restore_after_restarting(values: dict, processes: list[str]):
	"""Put preference keys back, and restart the processes an option restarts so they read them.
	Some (the Dock, SystemUIServer) write what they have loaded when they quit, so they are
	quit before the keys are restored as well as after."""
	for process in processes:
		subprocess.run(["killall", process], capture_output=True)
	time.sleep(2)
	restore_values(values)
	for process in processes:
		subprocess.run(["killall", process], capture_output=True)
	time.sleep(1)


def run_once_at_the_end(script: str) -> str:
	"""Several settings' scripts joined: lines they share (restarts, activateSettings) run once,
	where the last of them was, as they would in one activation."""
	lines = script.splitlines()
	last = {line: index for index, line in enumerate(lines)}
	return "\n".join(line for index, line in enumerate(lines) if last[line] == index)


def check_batch(data: dict, group: list[tuple[dict, dict]], build: str) -> tuple[int, int]:
	"""Check settings that are shown on the same page together: apply case n of every one of
	them, open the page once and read all their controls. They need the same number of cases,
	and expectations that don't depend on each other: each its own controls, and values that
	don't collide (e.g. a different test shortcut per row)."""
	spec = group[0][1]["verify"]
	commands = {setting["option"]: {json.dumps(case["value"]): command_for(setting["option"], case["value"])
		for case in entry["verify"]["expect"]} for setting, entry in group}
	storage = []
	for setting, entry in group:
		for key in storage_of(entry) + inventory.storage_from_commands(commands[setting["option"]]):
			if key.get("scope") != "system" and key not in storage:
				storage.append(key)
	before = storage_values(storage)
	failures = {setting["option"]: [] for setting, _ in group}
	try:
		for index in range(len(spec["expect"])):
			value_of_case = lambda entry: json.dumps(entry["verify"]["expect"][index]["value"])
			script = run_once_at_the_end("\n".join(commands[setting["option"]][value_of_case(entry)] for setting, entry in group))
			# System Settings writes back what it has open when it quits, so it goes first
			subprocess.run(["killall", "System Settings"], capture_output=True)
			time.sleep(1)
			subprocess.run(["/bin/bash", "-c", script], check=True)
			time.sleep(spec.get("settle", 1.5))
			first = next(iter(group[0][1]["verify"]["expect"][index]["controls"]))
			open_pane(spec["pane"], fresh=True, wait_for=None if spec["open"] else first, steps=spec["open"])
			time.sleep(1)
			for setting, entry in group:
				expectations = entry["verify"]["expect"][index]["controls"]
				failures[setting["option"]] += [f"{value_of_case(entry)}: {failure}" for failure in expectations_met(expectations)]
	finally:
		every = "\n".join(c for per in commands.values() for c in per.values())
		restore_after_restarting(before, sorted(set(re.findall(r"killall(?: -KILL)? '?([^' \n]+)'?", every))) + ["System Settings"])
		# restored keyboard shortcuts take effect like applied ones; activateSettings writes the
		# shortcuts back a moment later, so restore once more after it
		if "activateSettings" in every:
			subprocess.run([ACTIVATE_SETTINGS, "-u"], capture_output=True)
			time.sleep(3)
			restore_values(before)
		after = storage_values(storage)
		for key, value in before.items():
			if after.get(key) != value:
				print(f"RESTORE MISMATCH {key[0]} {key[1]}: was {value!r}, now {after.get(key)!r}")
	passed = failed = 0
	for setting, entry in group:
		label = f"{inventory.pane_label(data)} :: {setting['title']}"
		if failures[setting["option"]]:
			setting.pop("verified", None)
			print(f"FAIL {label}")
			for failure in failures[setting["option"]]:
				print(f"     {failure}")
			failed += 1
		else:
			print(f"ok   {label}")
			setting["verified"] = {"build": build, "date": datetime.date.today().isoformat(), "commands": inventory.commands_digest(entry)}
			passed += 1
	return passed, failed


def cmd_check(args):
	files = inventory.load_all()
	build = inventory.current_build()
	index = {o["option"]: o for o in inventory.load_option_index(None)}
	passed = failed = 0
	for path, data in files.items():
		if args.pane and inventory.normalize(args.pane) not in inventory.normalize(inventory.pane_label(data)):
			continue
		batches: dict[tuple, list] = {}
		for setting_id, setting in data["settings"].items():
			if args.setting and args.setting != setting_id:
				continue
			if args.skip and re.search(args.skip, setting["title"]):
				continue
			if args.only_unverified and setting.get("verified"):
				continue
			entry = index.get(setting.get("option"))
			if not (entry and entry.get("verify")):
				continue
			# nix-darwin's settings are applied as root
			if entry.get("module") == "darwin" and os.geteuid() != 0:
				continue
			if args.batch:
				spec = entry["verify"]
				page = (spec["pane"], tuple(spec["open"]), len(spec["expect"]))
				batches.setdefault(page, []).append((setting, entry))
				continue
			try:
				ok = check_setting(data, setting, build, entry)
			except Exception as error:  # one broken spec shouldn't stop the others
				print(f"FAIL {inventory.pane_label(data)} :: {setting['title']}\n     {error}")
				ok = False
			passed, failed = passed + ok, failed + (not ok)
		for group in batches.values():
			try:
				ok, bad = check_batch(data, group, build)
			except Exception as error:
				print(f"FAIL {inventory.pane_label(data)} :: {', '.join(s['title'] for s, _ in group)}\n     {error}")
				ok, bad = 0, len(group)
			passed, failed = passed + ok, failed + bad
		inventory.save_all(files)
	inventory.save_all(files)
	print(f"{passed} passed, {failed} failed")
	sys.exit(1 if failed else 0)


def main():
	parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
	sub = parser.add_subparsers(dest="command", required=True)

	p = sub.add_parser("controls")
	p.add_argument("pane")

	p = sub.add_parser("observe")
	p.add_argument("pane")
	p.add_argument("--open", action="append", help="control to press first, e.g. a sub-page (repeatable)")
	p.add_argument("ax", nargs="+", help="ax command, e.g. press \"Magnification\"")

	p = sub.add_parser("apply")
	p.add_argument("option")
	p.add_argument("value", help="JSON, e.g. true, 48, '\"dark\"'")

	p = sub.add_parser("discover", help="add the settings a pane shows to an inventory file")
	p.add_argument("pane")
	p.add_argument("inventory", help="inventory file, e.g. inventory/system-settings/appearance.json")
	p.add_argument("--open", action="append", help="control to press first (a sheet or sub-page), repeatable")
	p.add_argument("--section", help="section to file the settings under")

	p = sub.add_parser("probe", help="operate every control in a pane and record what it writes")
	p.add_argument("pane")
	p.add_argument("--open", action="append", help="control to press first (a sheet or sub-page), repeatable")
	p.add_argument("--skip", help="regex of control labels to leave alone, e.g. VoiceOver|Zoom")
	p.add_argument("--out", help="write the JSON here")
	p.add_argument("--max-choices", type=int, help="try at most this many choices of each pop-up")
	p.add_argument("--sheets", help="regex of button labels whose sheets to probe too, e.g. 'Advanced…|Options…'")

	p = sub.add_parser("check")
	p.add_argument("--pane")
	p.add_argument("--setting")
	p.add_argument("--skip", help="regex of setting titles to leave out, e.g. ones that play sound or speak")
	p.add_argument("--only-unverified", action="store_true", help="leave out settings that are verified already")
	p.add_argument("--batch", action="store_true", help="check the settings of one page together (much faster; see check_batch)")

	args = parser.parse_args()
	{"controls": cmd_controls, "observe": cmd_observe, "apply": cmd_apply, "check": cmd_check, "discover": cmd_discover, "probe": cmd_probe}[args.command](args)


if __name__ == "__main__":
	main()
