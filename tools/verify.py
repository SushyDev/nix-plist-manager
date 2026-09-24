#!/usr/bin/env python3
"""
verify — check options against the real System Settings UI.

    check [--pane P] [--option O] [--batch] [--skip regex] [--only-unverified]
        For every option with a `verify` spec: back up the keys it stores, apply each value in the
        spec, reopen System Settings and compare its controls against the spec, then put
        everything back. Passing options are recorded in coverage.json under the macOS build.
    discover <pane> [--open control…]
        List the settings a page shows: switches, sliders, pop-ups, pickers and "…" sheets.
    gaps [--pane name]
        List what System Settings shows that no option and no coverage.json entry accounts for.
    observe <pane> [--open control…] <ax command…>
        Operate a control, e.g. `observe <pane> click "Magnification"`, and print which
        preference keys it changed.

<pane> is the identifier of the pane's sidebar item, e.g. com.apple.settings.appearance
(`gaps` and `ax dump` list them).

A spec, on the setting in Nix:

    verify = {
      pane = "com.apple.settings.appearance";
      open = [ "Hot Corners…" ];                     # optional: controls to press first
      operate = [ "click" "TintWindowBackgroundToggle" ];  # optional, see below
      expect = {
        true = { TintWindowBackgroundToggle = 1; };
        false = { TintWindowBackgroundToggle = 0; };
      };
    };

`expect` maps each value to control labels (in ax.swift's label syntax) and the AXValue they
should show, or { selected = true; } for buttons that only show selection. `operate` flips the
control in the UI there and back (a toggle twice; otherwise [ [ "press" "A" ] [ "press" "B" ] ])
and fails unless that changes the keys the option writes, which catches options that write
somewhere System Settings doesn't read.

Requires Accessibility permission. The Swift tools are compiled on first use.
"""

from __future__ import annotations

import argparse
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
ROOT = Path(os.environ.get("NIX_PLIST_MANAGER_ROOT") or HERE.parent)
COVERAGE = ROOT / "coverage.json"
CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "nix-plist-manager"
ACTIVATE_SETTINGS = "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"


# --- System Settings, through ax.swift ------------------------------------------------------

def tool(name: str) -> str:
	source, binary = HERE / f"{name}.swift", CACHE / name
	if not binary.exists() or binary.stat().st_mtime < source.stat().st_mtime:
		CACHE.mkdir(parents=True, exist_ok=True)
		subprocess.run(["swiftc", "-O", str(source), "-o", str(binary)], check=True)
	return str(binary)


def ax(*args: str) -> str:
	result = subprocess.run([tool("ax"), *args], capture_output=True, text=True)
	if result.returncode != 0:
		raise RuntimeError(result.stderr.strip())
	return result.stdout


def dump(sheet: bool = False) -> list[dict]:
	try:
		text = ax("dump", "--sheet") if sheet else ax("dump")
	except RuntimeError:
		text = ax("dump")
	return [e for e in map(json.loads, text.splitlines()) if "Sidebar" not in e.get("path", [])]


def wait_until(attempt, what: str, timeout: float = 15):
	deadline = time.time() + timeout
	while True:
		try:
			return attempt()
		except RuntimeError:
			if time.time() > deadline:
				raise RuntimeError(f"timed out waiting for {what}")
			time.sleep(0.5)


def quit_settings():
	subprocess.run(["killall", "System Settings"], capture_output=True)
	time.sleep(1)


def open_pane(pane: str, fresh: bool = False, wait_for: str | None = None, steps: list[str] = ()):
	"""Show a pane by pressing its sidebar item. `fresh` quits System Settings first, so it
	rereads every preference. (x-apple.systempreferences: URLs sometimes land on the wrong pane.)"""
	if fresh:
		quit_settings()
	subprocess.run(["open", "-b", "com.apple.systempreferences"], check=True)

	restarted = False

	def show():
		nonlocal restarted
		try:
			return ax("press", pane)
		except RuntimeError as error:
			# once its window is closed, opening System Settings again doesn't bring one back;
			# a restart does, but it takes a moment to show the window
			if "no window" in str(error) and not restarted:
				restarted = True
				quit_settings()
				subprocess.run(["open", "-b", "com.apple.systempreferences"], check=True)
				raise
			# rows further down the sidebar only exist once scrolled to, which a click does
			return ax("click", pane)

	wait_until(show, f"sidebar item {pane}")
	for step in steps:
		# "click:<label>" clicks instead, for list rows that ignore AXPress
		action, target = ("click", step.removeprefix("click:")) if step.startswith("click:") else ("press", step)
		wait_until(lambda: ax(action, target), step)
		time.sleep(0.5)
	if wait_for:
		wait_until(lambda: ax("get", wait_for), wait_for)


# --- options and coverage.json --------------------------------------------------------------

def load_options() -> list[dict]:
	result = subprocess.run(["nix", "eval", "--json", f"path:{ROOT}#optionIndex"], capture_output=True, text=True)
	if result.returncode != 0:
		sys.exit(f"nix eval .#optionIndex failed:\n{result.stderr}")
	return json.loads(result.stdout)


def command_for(option: str, value) -> str:
	expr = f"f: f {json.dumps(option)} (builtins.fromJSON {json.dumps(json.dumps(value))})"
	result = subprocess.run(["nix", "eval", "--raw", f"path:{ROOT}#lib.commandFor", "--apply", expr], capture_output=True, text=True)
	if result.returncode != 0:
		raise RuntimeError(result.stderr.strip().splitlines()[-1])
	return result.stdout


def label_of(entry: dict) -> str:
	return " > ".join(entry["path"])


def load_coverage() -> dict:
	return json.loads(COVERAGE.read_text())


def save_coverage(coverage: dict):
	"""Verified options one per line, and each reason's settings on one line, so the file stays
	short and its diffs say what changed."""
	line = lambda value: json.dumps(value, ensure_ascii=False)
	lines = lambda values: "[\n" + ",\n".join(f"\t\t\t{line(v)}" for v in sorted(values)) + "\n\t\t]"
	grouped = lambda groups: ",\n".join(
		f"\t\t{line(pane)}: {{\n" + ",\n".join(f"\t\t\t{line(reason)}: {line(titles)}" for reason, titles in reasons.items()) + "\n\t\t}"
		for pane, reasons in sorted(groups.items()))
	verified = ",\n".join(f"\t\t{line(build)}: {lines(options)}" for build, options in sorted(coverage["verified"].items()) if options)
	COVERAGE.write_text(
		f'{{\n\t"verified": {{\n{verified}\n\t}},\n'
		f'\t"todo": {{\n{grouped(coverage["todo"])}\n\t}},\n'
		f'\t"notCovered": {{\n{grouped(coverage["notCovered"])}\n\t}}\n}}\n')


# --- preference keys: back up and restore ---------------------------------------------------

def has_root() -> bool:
	"""Running as root, or allowed to sudo without a password, so nix-darwin's settings can be
	applied and restored."""
	return os.geteuid() == 0 or subprocess.run(["sudo", "-n", "true"], capture_output=True).returncode == 0


def as_root(argv: list[str], root: bool = True) -> list[str]:
	return argv if not root or os.geteuid() == 0 else ["sudo", "-n", *argv]


def run_script(script: str, root: bool = False, check: bool = True):
	subprocess.run(as_root(["/bin/bash", "-c", script], root), check=check)


def storage_of(entry: dict, root: bool) -> list[tuple]:
	"""The keys to back up for an option: where it keeps its value, and what its values write
	besides (settings they imply), as (domain, key, byHost, system). System keys need root."""
	keys = entry["storage"] + [op["key"] for c in entry["candidates"] for op in c["ops"] if isinstance(op.get("key"), dict)]
	result = []
	for key in keys:
		system = key.get("scope") == "system"
		# a file or command rather than a preference key: the option puts that back itself
		if not key.get("key") or (system and not root):
			continue
		domain = f"/Library/Preferences/{key['domain']}" if system and not key["domain"].startswith("/") else key["domain"]
		result.append((domain, key["key"], bool(key.get("byHost")), system))
	return list(dict.fromkeys(result))


def storage_values(keys: list[tuple]) -> dict:
	values = {}
	for domain, key, by_host, system in keys:
		host = ["-currentHost"] if by_host else []
		result = subprocess.run(as_root(["defaults", *host, "export", domain, "-"], system), capture_output=True)
		exported = plistlib.loads(result.stdout) if result.returncode == 0 and result.stdout else {}
		values[(domain, key, by_host, system)] = exported.get(key)
	return values


def restore_values(values: dict):
	"""Put each key back as it was. `defaults import` merges, so a one-key plist restores just
	that key and leaves the rest of the domain alone."""
	for (domain, key, by_host, system), value in values.items():
		host = ["-currentHost"] if by_host else []
		if value is None:
			subprocess.run(as_root(["defaults", *host, "delete", domain, key], system), capture_output=True)
			continue
		with tempfile.NamedTemporaryFile(suffix=".plist", delete=False) as f:
			plistlib.dump({key: value}, f)
		os.chmod(f.name, 0o644)
		subprocess.run(as_root(["defaults", *host, "import", domain, f.name], system), check=True)
		os.unlink(f.name)


def restore_after_restarting(values: dict, processes: list[str]):
	"""Put keys back, restarting the processes the options restart so they read them. Some (the
	Dock, SystemUIServer) write what they have loaded when they quit, so they're quit first too."""
	for process in processes:
		subprocess.run(["killall", process], capture_output=True)
	time.sleep(2)
	restore_values(values)
	for process in processes:
		subprocess.run(["killall", process], capture_output=True)
	time.sleep(1)


# --- check ----------------------------------------------------------------------------------

def matches(actual: dict, expected) -> bool:
	if isinstance(expected, dict):
		return all(bool(actual.get(k)) == v if isinstance(v, bool) else actual.get(k) == v for k, v in expected.items())
	value = actual.get("value")
	if isinstance(expected, (int, float)) and isinstance(value, (int, float)):
		return abs(value - expected) < 1e-6
	if isinstance(expected, str) and isinstance(value, str):
		return value.strip() == expected.strip()  # some menus pad their titles
	return value == expected


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


def shown_values(group: list[dict]) -> dict:
	"""The spec value System Settings shows now for each option, to apply again at the end:
	restoring keys alone doesn't undo live state (e.g. dark mode)."""
	spec = group[0]["verify"]
	try:
		open_pane(spec["pane"], fresh=True, steps=spec["open"])
	except RuntimeError:
		return {}  # the page only exists for some values
	time.sleep(1)
	shown = {}
	for entry in group:
		case = next((c for c in entry["verify"]["expect"] if not expectations_met(c["controls"])), None)
		if case:
			shown[entry["option"]] = case["value"]
	return shown


def operating_writes(entry: dict, root: bool) -> list[str]:
	"""Operate the control in System Settings there and back: the keys the option writes have to
	change. If they don't, the option writes somewhere System Settings doesn't read (e.g. a ByHost
	copy that shadows the one it uses) or the spec operates the wrong control."""
	spec, keys = entry["verify"], storage_of(entry, root)
	there, back = spec["operate"] if isinstance(spec["operate"][0], list) else (spec["operate"], spec["operate"])
	open_pane(spec["pane"], fresh=True, wait_for=there[1], steps=spec["open"])
	time.sleep(1)
	if back != there:
		ax(*back)  # start from the "back" state, whatever was applied last
		time.sleep(1.5)
	# read through cfprefsd rather than the files, which are written seconds later
	before = storage_values(keys)
	ax(*there)
	time.sleep(1.5)
	after_there = storage_values(keys)
	ax(*back)
	time.sleep(1.5)
	after_back = storage_values(keys)
	# the key has to move and move back; "back" may be an equivalent value (a deleted key for false)
	if any(after_there[k] != before[k] and after_back[k] != after_there[k] for k in before):
		return []
	return [f"operating {there} in System Settings doesn't change what the option writes ({', '.join(k[1] for k in before)})"]


def run_once_at_the_end(script: str) -> str:
	"""Several options' scripts joined: lines they share (restarts, activateSettings) run once,
	where the last of them was, as in one activation."""
	lines = script.splitlines()
	last = {line: index for index, line in enumerate(lines)}
	return "\n".join(line for index, line in enumerate(lines) if last[line] == index)


def check_group(group: list[dict]) -> set[str]:
	"""Check options shown on the same page together: apply case n of each, open the page once
	and read all their controls. A group of one is a plain check. Returns the options that pass."""
	spec = group[0]["verify"]
	root = any(entry["module"] == "darwin" for entry in group)
	commands = {e["option"]: {json.dumps(c["value"]): command_for(e["option"], c["value"]) for c in e["verify"]["expect"]} for e in group}
	keys = list(dict.fromkeys(key for entry in group for key in storage_of(entry, root)))
	before = storage_values(keys)
	shown = shown_values(group)
	failures = {entry["option"]: [] for entry in group}
	try:
		for index in range(len(spec["expect"])):
			value = lambda entry: json.dumps(entry["verify"]["expect"][index]["value"])
			# System Settings writes back what it has open when it quits, so it goes first
			quit_settings()
			run_script(run_once_at_the_end("\n".join(commands[e["option"]][value(e)] for e in group)), root)
			time.sleep(spec.get("settle", 1.5))
			first = next(iter(spec["expect"][index]["controls"]))
			open_pane(spec["pane"], fresh=True, wait_for=None if spec["open"] else first, steps=spec["open"])
			time.sleep(1)
			for entry in group:
				failures[entry["option"]] += [f"{value(entry)}: {f}" for f in expectations_met(entry["verify"]["expect"][index]["controls"])]
		for entry in group:
			if entry["verify"]["operate"]:
				failures[entry["option"]] += operating_writes(entry, root)
	finally:
		every = "\n".join(c for per in commands.values() for c in per.values())
		run_script(run_once_at_the_end("\n".join(commands[o][json.dumps(v)] for o, v in shown.items())), root, check=False)
		restore_after_restarting(before, sorted(set(re.findall(r"killall(?: -KILL)? '?([^' \n]+)'?", every))) + ["System Settings"])
		# activateSettings writes keyboard shortcuts back a moment later, so restore once more after it
		if "activateSettings" in every:
			subprocess.run([ACTIVATE_SETTINGS, "-u"], capture_output=True)
			time.sleep(3)
			restore_values(before)
		for key, value in storage_values(keys).items():
			if value != before[key]:
				print(f"RESTORE MISMATCH {key[0]} {key[1]}: was {before[key]!r}, now {value!r}")
	for entry in group:
		print(f"{'FAIL' if failures[entry['option']] else 'ok  '} {label_of(entry)}")
		for failure in failures[entry["option"]]:
			print(f"     {failure}")
	return {option for option, failed in failures.items() if not failed}


def cmd_check(args):
	root = has_root()
	coverage = load_coverage()
	verified = {option for options in coverage["verified"].values() for option in options}
	groups: dict[tuple, list] = {}
	for entry in load_options():
		spec = entry.get("verify")
		if not spec or (args.option and args.option != entry["option"]) \
				or (args.pane and normalize(args.pane) not in normalize(label_of(entry))) \
				or (args.skip and re.search(args.skip, label_of(entry))) \
				or (args.only_unverified and entry["option"] in verified) \
				or (entry["module"] == "darwin" and not root):  # nix-darwin's settings need root
			continue
		page = (spec["pane"], tuple(spec["open"]), len(spec["expect"])) if args.batch else entry["option"]
		groups.setdefault(page, []).append(entry)

	passed, failed, errors = set(), set(), 0
	for group in groups.values():
		try:
			ok = check_group(group)
		except Exception as error:  # e.g. System Settings not opening: says nothing about the options
			print(f"ERROR {', '.join(label_of(e) for e in group)}\n     {error}")
			errors += 1
			continue
		passed |= ok
		failed |= {entry["option"] for entry in group} - ok

	# an option counts as verified on the build it last passed on
	build = subprocess.run(["sw_vers", "-buildVersion"], capture_output=True, text=True).stdout.strip()
	coverage["verified"] = {b: sorted(set(options) - passed - failed) for b, options in coverage["verified"].items()}
	coverage["verified"][build] = sorted(set(coverage["verified"].get(build, [])) | passed)
	save_coverage(coverage)
	print(f"{len(passed)} passed, {len(failed)} failed" + (f", {errors} pages couldn't be checked" if errors else ""))
	sys.exit(1 if failed or errors else 0)


# --- discover and gaps ----------------------------------------------------------------------

def is_identifier(label: str) -> bool:
	"""TintWindowBackgroundToggle, auto-hide-dock, position: names for code, not people."""
	return " " not in label and (bool(re.search(r"[a-z][A-Z]|-|_|\.", label)) or label.islower())


def human_label(labels: list[str]) -> str:
	"""The label a person reads. Grouped controls carry their own label and the group's, e.g.
	"On Desktop" in "Show items", which becomes "Show items > On Desktop"."""
	readable = list(dict.fromkeys(l for l in labels if not is_identifier(l)))
	if not readable:
		return labels[0]
	if len(readable) > 1 and labels.index(readable[0]) < labels.index(readable[-1]) - 1:
		return f"{readable[-1]} > {readable[0]}"
	return readable[0]


def discover(pane: str, steps: list[str] = ()) -> list[dict]:
	"""The settings a page shows: switches and checkboxes are bools, sliders numbers, pop-ups and
	groups of selectable buttons enums, and "…" buttons open sheets."""
	open_pane(pane, steps=steps)
	time.sleep(1)
	chrome = {"Go Back", "Go Forward", "Help", "Search"}
	# `steps` open a sheet or a sub-page; only a sheet's contents are separate from the pane
	entries = [e for e in dump(sheet=bool(steps)) if not chrome & set(e.get("labels", []))]
	found, group, last_text = [], None, None

	def flush():
		nonlocal group
		# a picker rather than a row of unrelated buttons: something in it is selected, or its
		# members say which setting they belong to
		if group and (group["labeled"] or any(m.get("selected") or m.get("value") == 1 for m in group["members"])):
			choices = [human_label(m["labels"]) for m in group["members"]]
			title = group["title"]
			if any(f["title"] == title for f in found):
				title = f"{title} ({'/'.join(choices)})"
			found.append({"title": title, "kind": "enum", "choices": choices})
		group = None

	for entry in entries:
		role, labels = entry["role"], entry.get("labels", [])
		if role == "AXStaticText":
			last_text = entry.get("value")
		elif role == "AXButton" and labels and labels[0].endswith("…"):
			flush()
			found.append({"title": labels[0], "kind": "sheet", "choices": []})
		elif role in ("AXButton", "AXRadioButton") and labels:
			# members of one picker share a second label ("Blue | Color") or follow each other
			title = labels[1] if len(labels) > 1 else last_text
			if group is None or group["title"] != title or group["role"] != role:
				flush()
				group = {"title": title, "members": [], "role": role, "labeled": len(labels) > 1}
			group["members"].append(entry)
		else:
			flush()
			kind = {"AXCheckBox": "bool", "AXSlider": "number", "AXPopUpButton": "enum"}.get(role)
			if kind and labels:
				found.append({"title": human_label(labels), "kind": kind, "choices": []})
	flush()
	return [f for f in found if f["title"]]


def cmd_discover(args):
	for found in discover(args.pane, args.open or []):
		print(f"{found['kind']:7} {found['title']}" + (f"  {found['choices']}" if found["choices"] else ""))


def normalize(title: str) -> str:
	return re.sub(r"[^a-z0-9]+", " ", title.replace("’", "'").lower()).strip()


def cmd_gaps(args):
	"""Every pane's top page, and every page a verify spec opens, compared against the words the
	options' UI paths, their specs and coverage.json use for that pane. What's left is a setting
	nobody has looked at yet, or a label that changed."""
	options, coverage = load_options(), load_coverage()
	open_pane("com.apple.settings.appearance")
	panes = {  # sidebar identifier → name
		e["labels"][-1]: e["labels"][0] for e in map(json.loads, ax("dump").splitlines())
		if "Sidebar" in e.get("path", []) and e["role"] == "AXButton" and len(e.get("labels", [])) == 2
	}
	known: dict[str, set[str]] = {}
	for entry in options:
		ui, spec = entry["path"], entry.get("verify")
		if ui[0] == "System Settings":
			known.setdefault(ui[1], set()).update(map(normalize, ui[2:]))
		if spec and spec["pane"] in panes:
			# the labels a spec reads controls by, which can differ from what the UI shows
			labels = [label for case in spec["expect"] for label in case["controls"]] + spec["open"]
			parts = [re.sub(r"^\w+:|#\d+$", "", part) for label in labels for part in re.split(r" > | \+ ", label)]
			known.setdefault(panes[spec["pane"]], set()).update(map(normalize, ui[1:] + parts))
	for listed in (coverage["todo"], coverage["notCovered"]):
		for pane, reasons in listed.items():
			known.setdefault(pane, set()).update(normalize(p) for titles in reasons.values() for t in titles for p in t.split(" › "))

	pages = {(pane, ()) for pane in panes} | {
		(e["verify"]["pane"], tuple(e["verify"]["open"])) for e in options if e.get("verify") and e["verify"]["pane"] in panes
	}
	for pane, steps in sorted(pages):
		name = panes[pane]
		if args.pane and normalize(args.pane) != normalize(name):
			continue
		try:
			found = discover(pane, list(steps))
		except RuntimeError as error:
			print(f"{' > '.join([name, *steps])}: couldn't open ({error})", flush=True)
			continue
		for f in found:
			# discover tells apart controls with the same label by their choices: "Style (Light/Dark)"
			if normalize(re.sub(r" \([^)]*\)$", "", f["title"])) not in known.get(name, set()):
				print(f"{' > '.join([name, *steps, f['title']])}  ({f['kind']})", flush=True)


# --- observe --------------------------------------------------------------------------------

def cmd_observe(args):
	open_pane(args.pane, fresh=bool(args.open), steps=args.open or [])
	time.sleep(1)
	watcher = subprocess.Popen([tool("watch")], stdout=subprocess.PIPE, text=True)
	watcher.stdout.readline()  # "watching …": ready
	ax(*args.ax)
	time.sleep(5)  # cfprefsd writes changes to disk a few seconds later
	watcher.terminate()
	print(watcher.stdout.read(), end="")


def main():
	parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
	sub = parser.add_subparsers(dest="command", required=True)

	p = sub.add_parser("check", help="check options with a verify spec against System Settings")
	p.add_argument("--pane", help="options whose UI path contains this")
	p.add_argument("--option", help="one option, e.g. applications.systemSettings.appearance.appearance")
	p.add_argument("--skip", help="regex of UI paths to leave out, e.g. ones that play sound or speak")
	p.add_argument("--only-unverified", action="store_true", help="leave out options that are verified already")
	p.add_argument("--batch", action="store_true", help="check the options of one page together (much faster)")
	p.set_defaults(run=cmd_check)

	p = sub.add_parser("discover", help="list the settings a page shows")
	p.add_argument("pane")
	p.add_argument("--open", action="append", help="control to press first (a sheet or sub-page), repeatable")
	p.set_defaults(run=cmd_discover)

	p = sub.add_parser("gaps", help="list what System Settings shows that coverage doesn't account for")
	p.add_argument("--pane", help="one pane, by its name in the sidebar")
	p.set_defaults(run=cmd_gaps)

	p = sub.add_parser("observe", help="operate a control and print the preference keys it changes")
	p.add_argument("pane")
	p.add_argument("--open", action="append", help="control to press first (a sheet or sub-page), repeatable")
	p.add_argument("ax", nargs="+", help='ax command, e.g. click "Magnification"')
	p.set_defaults(run=cmd_observe)

	args = parser.parse_args()
	args.run(args)


if __name__ == "__main__":
	main()
