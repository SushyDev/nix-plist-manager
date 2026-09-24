#!/usr/bin/env python3
"""
verify — check options against System Settings; needs Accessibility permission.

    check [--pane P] [--option O] [--batch] [--skip regex] [--only-unverified]
    defaults [--pane P] [--option O] [--batch] [--skip regex] [--missing]
    discover <pane> [--open control…]
    gaps [--pane name]
    observe <pane> [--open control…] <ax command…>

<pane> is a sidebar identifier such as com.apple.settings.appearance. A setting's spec:

    verify = {
      pane = "com.apple.settings.appearance";
      open = [ "Hot Corners…" ];
      operate = [ "click" "TintWindowBackgroundToggle" ];
      expect = {
        true = { TintWindowBackgroundToggle = 1; };
        false = { TintWindowBackgroundToggle = 0; };
      };
    };
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


def tool(name: str) -> str:
	source, binary = HERE / f"{name}.swift", CACHE / name
	if not binary.exists() or binary.stat().st_mtime < source.stat().st_mtime:
		CACHE.mkdir(parents=True, exist_ok=True)
		subprocess.run(["swiftc", "-O", str(source), "-o", str(binary)], check=True)
	return str(binary)


server: subprocess.Popen | None = None


def ax(*args: str) -> str:
	"""Runs an ax command in one long-lived ax process; starting one per command costs a quarter second."""
	global server
	if server is None or server.poll() is not None:
		server = subprocess.Popen([tool("ax"), "serve"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, bufsize=1)
	server.stdin.write(json.dumps(list(args)) + "\n")
	server.stdin.flush()
	lines = []
	for line in server.stdout:
		if line.startswith("\x04 "):
			status = line[2:].rstrip("\n")
			if status != "ok":
				raise RuntimeError(f"ax: {status}")
			return "".join(lines)
		lines.append(line)
	server = None
	raise RuntimeError("ax: the ax process stopped")


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
			time.sleep(0.15)


def poll(check, timeout: float):
	"""check() until it's true or the time is up; returns its last result."""
	deadline = time.time() + timeout
	while True:
		result = check()
		if result or time.time() > deadline:
			return result
		time.sleep(0.2)


def settings_window():
	"""Launch System Settings if needed and wait for its window; one closed earlier only comes
	back with a relaunch."""
	subprocess.run(["open", "-b", "com.apple.systempreferences"], check=True)
	for attempt in range(2):
		deadline = time.time() + 8
		while time.time() < deadline:
			try:
				return ax("values")
			except RuntimeError:
				time.sleep(0.2)
		quit_settings()
		subprocess.run(["open", "-b", "com.apple.systempreferences"], check=True)
	raise RuntimeError("System Settings shows no window")


def quit_settings():
	# a normal quit makes System Settings write what it shows back to the preferences
	subprocess.run(["killall", "-KILL", "System Settings"], capture_output=True)
	time.sleep(0.5)


def open_pane(pane: str, fresh: bool = False, wait_for: str | None = None, steps: list[str] = ()):
	# x-apple.systempreferences: URLs sometimes land on the wrong pane
	if fresh:
		quit_settings()
	settings_window()

	def show():
		try:
			return ax("press", pane)
		except RuntimeError:
			# sidebar rows only exist once scrolled to, which a click does
			return ax("click", pane)

	wait_until(show, f"sidebar item {pane}")
	for step in steps:
		action, target = ("click", step.removeprefix("click:")) if step.startswith("click:") else ("press", step)
		wait_until(lambda: ax(action, target), step)
		time.sleep(0.2)
	if wait_for:
		wait_until(lambda: ax("get", wait_for), wait_for)


# pages that keep showing old values, or write them back when they're left, until System
# Settings is quit without saving and relaunched
stale_pages: set[tuple] = set()


def settled(keys: list[tuple], quiet: float = 0.5, timeout: float = 4) -> dict:
	"""The keys once they've stopped changing; activateSettings rewrites shortcuts a moment later."""
	last, since, deadline = storage_values(keys), time.time(), time.time() + timeout
	while time.time() - since < quiet and time.time() < deadline:
		time.sleep(0.2)
		now = storage_values(keys)
		if now != last:
			last, since = now, time.time()
	return last


# pages that show a written value without being reloaded, and ones that don't
live_pages: set[tuple] = set()
reloaded_pages: set[tuple] = set()


def apply_and_show(spec: dict, script: str, keys: list[tuple], root: bool, wait_for: str | None = None, shown=None):
	"""Write, then show the page with what was written: some pages show it by themselves, most
	after being switched away from and back, the rest after a relaunch. `shown` says whether the
	page shows what's expected."""
	page = page_of(spec)
	if shown and page not in reloaded_pages and page not in stale_pages:
		run_script(script, root)
		if "activateSettings" in script:
			settled(keys)
		if poll(shown, 0.8):
			live_pages.add(page)
			return
		reloaded_pages.add(page)
		live_pages.discard(page)
	if page_of(spec) in stale_pages:
		quit_settings()  # before writing, so the open page can't write its values back
	run_script(script, root)
	time.sleep(spec.get("settle", 0.3))
	written = settled(keys) if "activateSettings" in script else storage_values(keys)
	refresh(spec, wait_for)
	if page_of(spec) not in stale_pages and storage_values(keys) != written:
		stale_pages.add(page_of(spec))
		apply_and_show(spec, script, keys, root, wait_for)


def page_of(spec: dict) -> tuple:
	return (spec["pane"], tuple(spec["open"]))


def refresh(spec: dict, wait_for: str | None = None, relaunch: bool = False):
	"""Show the page with what's stored now: switching to another pane and back reloads most
	pages; the rest need System Settings relaunched."""
	if relaunch or page_of(spec) in stale_pages:
		open_pane(spec["pane"], fresh=True, wait_for=wait_for, steps=spec["open"])
		return
	for label in ("Done", "OK", "Cancel"):  # an open sheet blocks the sidebar
		try:
			ax("press", f"AXButton:{label}")
			time.sleep(0.3)
			break
		except RuntimeError:
			pass
	other = "com.apple.settings.general" if spec["pane"] != "com.apple.settings.general" else "com.apple.settings.appearance"
	try:
		ax("press", other)
		time.sleep(0.2)
		open_pane(spec["pane"], wait_for=wait_for, steps=spec["open"])
	except RuntimeError:
		refresh(spec, wait_for, relaunch=True)


def load_options() -> list[dict]:
	result = subprocess.run(["nix", "eval", "--json", f"path:{ROOT}#optionIndex"], capture_output=True, text=True)
	if result.returncode != 0:
		sys.exit(f"nix eval .#optionIndex failed:\n{result.stderr}")
	return json.loads(result.stdout)


commands: dict[tuple, str] = {}


def prepare_commands(pairs: list[tuple]):
	"""Evaluate the scripts for (option, value) pairs in one go; evaluating each alone costs a second."""
	wanted = [{"option": o, "value": v} for o, v in dict.fromkeys((o, json.dumps(v)) for o, v in pairs) if (o, v) not in commands]
	wanted = [{"option": w["option"], "value": json.loads(w["value"])} for w in wanted]
	if not wanted:
		return
	with tempfile.NamedTemporaryFile("w", suffix=".json") as file:
		json.dump(wanted, file)
		file.flush()
		expr = f"f: map (p: f p.option p.value) (builtins.fromJSON (builtins.readFile {file.name}))"
		result = subprocess.run(["nix", "eval", "--json", "--impure", f"path:{ROOT}#lib.commandFor", "--apply", expr], capture_output=True, text=True)
	if result.returncode != 0:
		raise RuntimeError(result.stderr.strip().splitlines()[-1])
	for pair, script in zip(wanted, json.loads(result.stdout)):
		commands[(pair["option"], json.dumps(pair["value"]))] = script


def command_for(option: str, value) -> str:
	prepare_commands([(option, value)])
	return commands[(option, json.dumps(value))]


def label_of(entry: dict) -> str:
	return " > ".join(entry["path"])


def load_coverage() -> dict:
	return json.loads(COVERAGE.read_text())


def save_coverage(coverage: dict):
	line = lambda value: json.dumps(value, ensure_ascii=False)
	lines = lambda values: "[\n" + ",\n".join(f"\t\t\t{line(v)}" for v in sorted(values)) + "\n\t\t]"
	grouped = lambda groups: ",\n".join(
		f"\t\t{line(pane)}: {{\n" + ",\n".join(f"\t\t\t{line(reason)}: {line(titles)}" for reason, titles in reasons.items()) + "\n\t\t}"
		for pane, reasons in sorted(groups.items()))
	verified = ",\n".join(f"\t\t{line(build)}: {lines(options)}" for build, options in sorted(coverage["verified"].items()) if options)
	COVERAGE.write_text(
		f'{{\n\t"verified": {{\n{verified}\n\t}},\n'
		f'\t"todo": {{\n{grouped(coverage["todo"])}\n\t}},\n'
		f'\t"notCovered": {{\n{grouped(coverage["notCovered"])}\n\t}},\n'
		f'\t"notSettings": {{\n{grouped(coverage["notSettings"])}\n\t}}\n}}\n')


def has_root() -> bool:
	return os.geteuid() == 0 or subprocess.run(["sudo", "-n", "true"], capture_output=True).returncode == 0


def as_root(argv: list[str], root: bool = True) -> list[str]:
	return argv if not root or os.geteuid() == 0 else ["sudo", "-n", *argv]


def run_script(script: str, root: bool = False, check: bool = True):
	subprocess.run(as_root(["/bin/bash", "-c", script], root), check=check)


def storage_of(entry: dict, root: bool) -> list[tuple]:
	result = []
	for key in entry["storage"]:
		system = key.get("scope") == "system"
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
	# `defaults import` merges, so a one-key plist restores only that key
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
	# the Dock and SystemUIServer write what they have loaded when they quit
	for process in processes:
		subprocess.run(["killall", process], capture_output=True)
	if processes:
		time.sleep(2)
	restore_values(values)
	for process in processes:
		subprocess.run(["killall", process], capture_output=True)
	if processes:
		time.sleep(1)


BACKUP = CACHE / "restore.plist"
NOISE = re.compile(r"LastUpdate|Timestamp|LastSeen|lastUsed|LaunchCount|WindowFrame|NSWindow|NSSplitView|NSNavPanel|NSToolbar|MRU|Recent|History|Session", re.I)


def export_domain(domain: str, by_host: bool, system: bool) -> dict:
	host = ["-currentHost"] if by_host else []
	result = subprocess.run(as_root(["defaults", *host, "export", domain, "-"], system), capture_output=True)
	return plistlib.loads(result.stdout) if result.returncode == 0 and result.stdout else {}


def domain_snapshot(keys: list[tuple]) -> dict:
	"""Whole domains, because turning a feature on can make its agent write other keys there
	(Switch Control writes its scanning intervals)."""
	return {(d, b, s): export_domain(d, b, s) for d, b, s in dict.fromkeys((d, b, s) for d, _, b, s in keys)}


def restore_domains(snapshot: dict, declared: set) -> list[tuple]:
	"""Put back keys that changed in the snapshot's domains besides the declared ones."""
	side = []
	for (domain, by_host, system), old in snapshot.items():
		now = export_domain(domain, by_host, system)
		for key in set(old) | set(now):
			if old.get(key) != now.get(key) and not NOISE.search(key) and (domain, key, by_host, system) not in declared:
				side.append((domain, key, by_host, system))
		restore_values({k: old.get(k[1]) for k in side if k[0] == domain and k[2] == by_host and k[3] == system})
	return side


def save_backup(before: dict, scripts: list[str], root: bool, domains: dict | None = None):
	"""Kept on disk until the values are back, so an interrupted run can still put them back."""
	CACHE.mkdir(parents=True, exist_ok=True)
	entries = [{"key": list(key), **({"value": value} if value is not None else {})} for key, value in before.items()]
	snapshots = [{"domain": list(key), "values": values} for key, values in (domains or {}).items()]
	BACKUP.write_bytes(plistlib.dumps({"entries": entries, "scripts": scripts, "root": root, "domains": snapshots}))


def restore_backup():
	if not BACKUP.exists():
		return
	saved = plistlib.loads(BACKUP.read_bytes())
	print(f"putting back the values an interrupted run left in {BACKUP}")
	restore_values({tuple(e["key"]): e.get("value") for e in saved["entries"]})
	restore_domains({tuple(d["domain"]): d["values"] for d in saved.get("domains", [])}, set())
	run_script(run_once_at_the_end("\n".join(saved["scripts"])), saved["root"], check=False)
	BACKUP.unlink()


def matches(actual: dict, expected) -> bool:
	if isinstance(expected, dict):
		return all(bool(actual.get(k)) == v if isinstance(v, bool) else actual.get(k) == v for k, v in expected.items())
	value = actual.get("value")
	if isinstance(expected, (int, float)) and isinstance(value, (int, float)):
		return abs(value - expected) < 1e-6
	if isinstance(expected, str) and isinstance(value, str):
		return value.strip() == expected.strip()  # some menus pad their titles
	return value == expected


def read_controls(labels) -> dict:
	labels = list(dict.fromkeys(labels))
	try:
		return json.loads(ax("values", *labels)) if labels else {}
	except (RuntimeError, ValueError) as error:
		return {label: {"error": str(error)} for label in labels}


def expectations_met(expectations: dict, controls: dict | None = None) -> list[str]:
	controls = controls if controls is not None else read_controls(expectations)
	failures = []
	for control, expected in expectations.items():
		actual = controls.get(control, {"error": "not read"})
		if "error" in actual:
			failures.append(f"{control}: {actual['error']}")
			continue
		if not matches(actual, expected):
			shown = {k: actual.get(k) for k in ("value", "selected") if k in actual}
			failures.append(f"{control}: expected {expected}, got {shown}")
	return failures


def open_for_reading(spec: dict, group: list[dict]) -> dict:
	"""What the page shows now; nothing when the page only exists for some values."""
	try:
		refresh(spec)
	except RuntimeError:
		return {}
	return shown_values(group, opened=True)


def shown_now(group: list[dict]) -> dict:
	"""Which of its spec's values each option shows, read in one go; None when it's none of them."""
	controls = read_controls(label for entry in group for case in entry["verify"]["expect"] for label in case["controls"])
	return {
		entry["option"]: next((c["value"] for c in entry["verify"]["expect"] if not expectations_met(c["controls"], controls)), None)
		for entry in group
	}


def shown_values(group: list[dict], opened: bool = False) -> dict:
	# restoring keys alone doesn't undo live state such as dark mode
	spec = group[0]["verify"]
	if not opened:
		try:
			open_pane(spec["pane"], steps=spec["open"])
		except RuntimeError:
			return {}  # the page only exists for some values
	shown = poll(lambda: (lambda now: now if None not in now.values() else None)(shown_now(group)), 3) or shown_now(group)
	return {option: value for option, value in shown.items() if value is not None}


def operating_writes(entry: dict, root: bool) -> list[str]:
	# catches options that write somewhere System Settings doesn't read, such as a ByHost copy
	spec, keys = entry["verify"], storage_of(entry, root)
	there, back = spec["operate"] if isinstance(spec["operate"][0], list) else (spec["operate"], spec["operate"])
	refresh(spec, there[1])
	if back != there:
		ax(*back)  # start from the "back" state, whatever was applied last
		time.sleep(1)
	before = storage_values(keys)
	ax(*there)
	after_there = poll(lambda: (lambda now: now if now != before else None)(storage_values(keys)), 3) or storage_values(keys)
	ax(*back)
	after_back = poll(lambda: (lambda now: now if now != after_there else None)(storage_values(keys)), 3) or storage_values(keys)
	# "back" may be an equivalent value, like a deleted key for false
	if any(after_there[k] != before[k] and after_back[k] != after_there[k] for k in before):
		return []
	return [f"operating {there} in System Settings doesn't change what the option writes ({', '.join(k[1] for k in before)})"]


def run_once_at_the_end(script: str) -> str:
	lines = script.splitlines()
	last = {line: index for index, line in enumerate(lines)}
	return "\n".join(line for index, line in enumerate(lines) if last[line] == index)


def put_back(keys: list[tuple], before: dict, scripts: list[str], shown_scripts: list[str], root: bool, domains: dict | None = None):
	every = "\n".join(scripts)
	run_script(run_once_at_the_end("\n".join(shown_scripts)), root, check=False)
	restore_after_restarting(before, sorted(set(re.findall(r"killall(?: -KILL)? '?([^' \n]+)'?", every)) - {"System Settings"}))
	# activateSettings writes keyboard shortcuts back a moment later
	if "activateSettings" in every:
		subprocess.run([ACTIVATE_SETTINGS, "-u"], capture_output=True)
		if settled(keys) != before:
			restore_values(before)
	for key in restore_domains(domains or {}, set(keys)):
		print(f"     put back {key[0]} {key[1]}, which the page changed besides its own keys")
	mismatched = [key for key, value in storage_values(keys).items() if value != before[key]]
	for key in mismatched:
		print(f"RESTORE MISMATCH {key[0]} {key[1]}: was {before[key]!r}, now {storage_values([key])[key]!r}")
	if not mismatched:
		BACKUP.unlink(missing_ok=True)


def case_of(entry: dict, index: int) -> dict:
	"""A page's options are checked together, so shorter specs repeat their values."""
	cases = entry["verify"]["expect"]
	return cases[index % len(cases)]


def check_group(group: list[dict]) -> set[str]:
	spec = group[0]["verify"]
	root = any(entry["module"] == "darwin" for entry in group)
	rounds = max(len(entry["verify"]["expect"]) for entry in group)
	scripts = {e["option"]: {json.dumps(c["value"]): command_for(e["option"], c["value"]) for c in e["verify"]["expect"]} for e in group}
	keys = list(dict.fromkeys(key for entry in group for key in storage_of(entry, root)))
	before = storage_values(keys)
	domains = domain_snapshot(keys)
	shown = open_for_reading(spec, group)
	shown_scripts = [scripts[o][json.dumps(v)] for o, v in shown.items() if o in scripts]
	save_backup(before, shown_scripts, root, domains)
	failures = {entry["option"]: [] for entry in group}
	try:
		for index in range(rounds):
			value = lambda entry: json.dumps(case_of(entry, index)["value"])
			wait_for = None if spec["open"] else next(iter(case_of(group[0], index)["controls"]))

			def misses():
				controls = read_controls(label for e in group for label in case_of(e, index)["controls"])
				return {e["option"]: expectations_met(case_of(e, index)["controls"], controls) for e in group}

			all_shown = lambda: (lambda m: m if not any(m.values()) else None)(misses())
			apply_and_show(spec, run_once_at_the_end("\n".join(scripts[e["option"]][value(e)] for e in group)), keys, root, wait_for,
				shown=lambda: not any(misses().values()))
			missed = poll(all_shown, 3) or misses()
			# a stale view isn't a failure: relaunch and look again
			if any(missed.values()) and page_of(spec) not in stale_pages:
				refresh(spec, wait_for, relaunch=True)
				missed = poll(all_shown, 4) or misses()
				if not any(missed.values()):
					stale_pages.add(page_of(spec))
			for entry in group:
				failures[entry["option"]] += [f"{value(entry)}: {f}" for f in missed[entry["option"]]]
		for entry in group:
			if entry["verify"]["operate"]:
				failures[entry["option"]] += operating_writes(entry, root)
	finally:
		put_back(keys, before, [c for per in scripts.values() for c in per.values()], shown_scripts, root, domains)
	for entry in group:
		print(f"{'FAIL' if failures[entry['option']] else 'ok  '} {label_of(entry)}")
		for failure in failures[entry["option"]]:
			print(f"     {failure}")
	return {option for option, failed in failures.items() if not failed}


PREFERENCE_ONLY = re.compile(r"^\s*(/usr/bin/(defaults|killall|notifyutil)\b|current=|case |/usr/bin/osascript -l JavaScript -e 'ObjC\.import\('Foundation'\);var d = \$\.NSUserDefaults|" + re.escape(ACTIVATE_SETTINGS) + ")")


def applies_live(entry: dict) -> bool:
	return any(not PREFERENCE_ONLY.match(line) for script in entry["commands"].values() for line in script.splitlines() if line.strip())


def default_group(group: list[dict]) -> dict:
	spec = group[0]["verify"]
	root = any(entry["module"] == "darwin" for entry in group)
	keys = list(dict.fromkeys(key for entry in group for key in storage_of(entry, root)))
	before = storage_values(keys)
	domains = domain_snapshot(keys)
	before_shown = open_for_reading(spec, group)
	# restoring the keys puts back everything that isn't applied live
	shown_scripts = [command_for(e["option"], before_shown[e["option"]]) for e in group if applies_live(e) and e["option"] in before_shown]
	unset = [entry["commands"]["unset"] for entry in group]
	save_backup(before, shown_scripts, root, domains)
	read = lambda entries: poll(lambda: (lambda now: now if None not in now.values() else None)(shown_now(entries)), 3) or shown_now(entries)
	try:
		apply_and_show(spec, run_once_at_the_end("\n".join(unset)), keys, root)
		found = read(group)
		# the same value as before can be the default or a view that didn't reload: relaunch to tell
		unsure = [e for e in group if found[e["option"]] is None or found[e["option"]] == before_shown.get(e["option"])]
		if unsure and page_of(spec) not in stale_pages:
			refresh(spec, relaunch=True)
			again = read(unsure)
			if any(again[o] != found[o] for o in again):
				stale_pages.add(page_of(spec))
			found.update(again)
		found = {option: value for option, value in found.items() if value is not None}
	finally:
		put_back(keys, before, unset + shown_scripts, shown_scripts, root, domains)
	for entry in group:
		shown_default = json.dumps(found[entry["option"]], ensure_ascii=False) if entry["option"] in found else "none of the spec's values"
		print(f"{label_of(entry)}: {shown_default}")
	return found


def select(args, verified: set = frozenset()) -> list[list[dict]]:
	root = has_root()
	groups: dict[tuple, list] = {}
	for entry in load_options():
		spec = entry.get("verify")
		if not spec or not spec["expect"] or (args.option and args.option != entry["option"]) \
				or (args.pane and normalize(args.pane) not in normalize(label_of(entry))) \
				or (args.skip and re.search(args.skip, label_of(entry))) \
				or ((getattr(args, "only_unverified", False) or getattr(args, "missing", False)) and entry["option"] in verified) \
				or (args.command == "defaults" and "unset" not in entry["commands"]) \
				or (spec["sideEffects"] and not args.side_effects) \
				or (entry["module"] == "darwin" and not root):  # nix-darwin's settings need root
			continue
		page = (spec["pane"], tuple(spec["open"])) if args.batch else entry["option"]
		groups.setdefault(page, []).append(entry)
	return list(groups.values())


def build() -> str:
	return subprocess.run(["sw_vers", "-buildVersion"], capture_output=True, text=True).stdout.strip()


def start(groups: list[list[dict]]):
	restore_backup()
	prepare_commands([(e["option"], c["value"]) for group in groups for e in group for c in e["verify"]["expect"]])


def cmd_defaults(args):
	path = ROOT / "defaults" / f"{build()}.json"
	defaults = json.loads(path.read_text()) if path.exists() else {}
	groups = select(args, set(defaults) if args.missing else frozenset())
	start(groups)
	for group in groups:
		try:
			defaults.update(default_group(group))
		except Exception as error:
			print(f"ERROR {', '.join(label_of(e) for e in group)}\n     {error}")
			continue
		path.parent.mkdir(exist_ok=True)
		path.write_text("{\n" + ",\n".join(f"\t{json.dumps(o)}: {json.dumps(v, ensure_ascii=False)}" for o, v in sorted(defaults.items())) + "\n}\n")
	quit_settings()
	print(f"{len(defaults)} defaults in {path.relative_to(ROOT)}")


def cmd_check(args):
	coverage = load_coverage()
	verified = {option for options in coverage["verified"].values() for option in options}
	groups = {index: group for index, group in enumerate(select(args, verified))}
	start(list(groups.values()))

	passed, failed, errors = set(), set(), 0
	for group in groups.values():
		try:
			ok = check_group(group)
			# values of options on one page can depend on each other: check failures on their own
			for entry in (e for e in group if e["option"] not in ok and len(group) > 1):
				print(f"     again on its own: {label_of(entry)}")
				ok |= check_group([entry])
		except Exception as error:  # e.g. System Settings not opening: says nothing about the options
			print(f"ERROR {', '.join(label_of(e) for e in group)}\n     {error}")
			errors += 1
			continue
		passed |= ok
		failed |= {entry["option"] for entry in group} - ok

	build_version = build()
	coverage["verified"] = {b: sorted(set(options) - passed - failed) for b, options in coverage["verified"].items()}
	coverage["verified"][build_version] = sorted(set(coverage["verified"].get(build_version, [])) | passed)
	save_coverage(coverage)
	quit_settings()
	print(f"{len(passed)} passed, {len(failed)} failed" + (f", {errors} pages couldn't be checked" if errors else ""))
	sys.exit(1 if failed or errors else 0)


def is_identifier(label: str) -> bool:
	return " " not in label and (bool(re.search(r"[a-z][A-Z]|-|_|\.", label)) or label.islower())


def human_label(labels: list[str]) -> str:
	readable = list(dict.fromkeys(l for l in labels if not is_identifier(l)))
	if not readable:
		return labels[0]
	if len(readable) > 1 and labels.index(readable[0]) < labels.index(readable[-1]) - 1:
		return f"{readable[-1]} > {readable[0]}"
	return readable[0]


def discover(pane: str, steps: list[str] = ()) -> list[dict]:
	open_pane(pane, steps=steps)
	time.sleep(1)
	chrome = {"Go Back", "Go Forward", "Help", "Search"}
	entries = [e for e in dump(sheet=bool(steps)) if not chrome & set(e.get("labels", []))]
	found, group, last_text = [], None, None

	def flush():
		nonlocal group
		# unlike a row of unrelated buttons, a picker has a selected or labeled member
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
			# spec labels can differ from what the UI shows
			labels = [label for case in spec["expect"] for label in case["controls"]] + spec["open"]
			parts = [re.sub(r"^\w+:|#\d+$", "", part) for label in labels for part in re.split(r" > | \+ ", label)]
			known.setdefault(panes[spec["pane"]], set()).update(map(normalize, ui[1:] + parts))
	for listed in (coverage["todo"], coverage["notCovered"], coverage["notSettings"]):
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
			# discover adds the choices to repeated labels: "Style (Light/Dark)"
			if normalize(re.sub(r" \([^)]*\)$", "", f["title"])) not in known.get(name, set()):
				print(f"{' > '.join([name, *steps, f['title']])}  ({f['kind']})", flush=True)


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
	p.add_argument("--side-effects", action="store_true", help="also options whose check has side effects, such as turning on the camera")
	p.set_defaults(run=cmd_check)

	p = sub.add_parser("defaults", help="record what System Settings shows once each option's keys are deleted")
	p.add_argument("--pane", help="options whose UI path contains this")
	p.add_argument("--option", help="one option")
	p.add_argument("--skip", help="regex of UI paths to leave out")
	p.add_argument("--batch", action="store_true", help="the options of one page together")
	p.add_argument("--missing", action="store_true", help="only options with no default recorded yet, e.g. to continue a run")
	p.add_argument("--side-effects", action="store_true", help="also options whose check has side effects, such as turning on the camera")
	p.set_defaults(run=cmd_defaults)

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
