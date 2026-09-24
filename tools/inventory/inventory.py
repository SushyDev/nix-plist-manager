#!/usr/bin/env python3
"""
inventory — track every macOS setting and whether nix-plist-manager implements it.

The inventory lives in inventory/**.json, one file per settings pane (or application).
Each file lists the settings found in that pane and what we know about them.
See CONTRIBUTING.md for the workflow.

Commands:
    extract   Scan this Mac for settings (App Intents metadata + settings search terms)
              and merge them into the inventory. macOS only.
    sync      Check off settings implemented by an option (reads the flake's optionIndex).
    report    Regenerate inventory/COVERAGE.md.
    check     Validate the inventory and fail if COVERAGE.md is stale (for CI).
    link      Link an option to a discovered setting when sync couldn't match it by title.
    merge     Fold a duplicate entry into another.
    skip      Mark a setting as not worth an option, with a reason.
    todo      List settings by status, e.g. `todo --pane Keyboard --status todo`.

Run with:
    python3 tools/inventory/inventory.py <command>
    nix run .#inventory -- <command>
"""

from __future__ import annotations

import argparse
import glob
import hashlib
import json
import os
import re
import subprocess
import sys
import unicodedata
from collections import Counter
from pathlib import Path

# `nix run .#inventory` runs a copy from the store, so it passes the checkout in explicitly
ROOT = Path(os.environ.get("NIX_PLIST_MANAGER_ROOT") or Path(__file__).resolve().parents[2])
INVENTORY_DIR = ROOT / "inventory"
COVERAGE_FILE = INVENTORY_DIR / "COVERAGE.md"

EXTENSIONS_DIR = "/System/Library/ExtensionKit/Extensions"
APPLICATIONS_DIR = "/System/Applications"
SETTINGS_EXTENSION_POINT = "com.apple.Settings.extension.ui"

STATUSES = ["verified", "implemented", "mapped", "todo", "skipped"]
KINDS = ["bool", "number", "string", "enum", "unknown"]
SETTING_FIELDS = {
	"title", "section", "kind", "choices", "sources", "firstSeen", "lastSeen",
	"storage", "option", "verified", "skip", "notes", "ui",
}
STORAGE_FIELDS = {"domain", "key", "type", "byHost", "scope"}


# ---------------------------------------------------------------------------
# Tables contributors are expected to extend
# ---------------------------------------------------------------------------

# Sidebar names that differ from what the pane bundle reports about itself
PANE_NAME_OVERRIDES = {
	"com.apple.Battery-Settings.extension": "Battery",
	"com.apple.HeadphoneSettings": "Headphones",
	"com.apple.Siri-Settings.extension": "Apple Intelligence & Siri",
	"com.apple.FollowUpSettings.FollowUpSettingsExtension": "Follow Ups",
}

# App Intents bundles that describe System Settings, and the pane they belong to
INTENT_BUNDLE_PANES = {
	"AccessibilitySettingsWidgetExtension.appex": ["Accessibility"],
	"AirDropHandoffIntentsExtension.appex": ["General", "AirDrop & Continuity"],
	"AppearanceIntentsExtension.appex": ["Appearance"],
	"BatterySettingsIntentsExtension.appex": ["Battery"],
	"BluetoothSettingsAppIntentsWidgetExtension.appex": ["Bluetooth"],
	"ControlCenterSettingsIntents.appex": ["Menu Bar"],
	"DateTimeIntentsExtension.appex": ["General", "Date & Time"],
	"DesktopSettingsIntents.appex": ["Desktop & Dock"],
	"DisplaysSettingsIntentsExtension.appex": ["Displays"],
	"LockScreenIntentsExtension.appex": ["Lock Screen"],
	"MouseIntentsExtension.appex": ["Mouse"],
	"NotificationsSettingsIntents.appex": ["Notifications"],
	"PrinterScannerIntentsExtension.appex": ["Printers & Scanners"],
	"SoundIntentsExtension.appex": ["Sound"],
	"TrackpadIntentsExtension.appex": ["Trackpad"],
	"VPNAppIntentWidgetExtension.appex": ["VPN"],
	"WallpaperSettingsIntents.appex": ["Wallpaper"],
}

# Entities that expose state or content rather than a setting
IGNORED_ENTITIES = {
	"CurrentlyConnectedVPN",
	"GroupEntity", "ListEntity", "SectionEntity",  # Reminders content
	"BookSettingsEntity",  # per-book reader state
}

# Accessibility entity titles are localisation keys like AX.SpokenContent.axSpokenAlerts.title;
# the second component names the sub-pane
ACCESSIBILITY_SECTIONS = {
	"Audio": "Audio",
	"AudioDescriptions": "Audio Descriptions",
	"Display": "Display",
	"HoverText": "Hover Text",
	"Keyboard": "Keyboard",
	"LiveCaptions": "Live Captions",
	"LiveSpeech": "Live Speech",
	"Motion": "Motion",
	"PointerControl": "Pointer Control",
	"RTT": "RTT",
	"Siri": "Siri",
	"SpokenContent": "Spoken Content",
	"SubtitlesandCaptioning": "Subtitles & Captioning",
	"SwitchControl": "Switch Control",
	"VocalShortcuts": "Vocal Shortcuts",
	"VoiceControl": "Voice Control",
	"VoiceOver": "VoiceOver",
	"Zoom": "Zoom",
}

# Option UI paths (lib/options) that don't name the pane the way the sidebar does
OPTION_PANE_ALIASES = {
	"Control Center": ["Menu Bar"],
	"Notification": ["Notifications"],
	"Date & Time": ["General", "Date & Time"],
	"Software Update": ["General", "Software Update"],
}

# App Intents primitive type identifiers
PRIMITIVE_KINDS = {0: "string", 1: "bool", 2: "number", 3: "number", 7: "number"}


# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------

def plist_json(path: str, key: str | None = None):
	"""Read a plist (or one key of it) as JSON via plutil. Returns None when unreadable."""
	args = ["plutil"] + (["-extract", key, "json"] if key else ["-convert", "json"]) + ["-o", "-", path]
	result = subprocess.run(args, capture_output=True)
	if result.returncode != 0:
		return None
	try:
		return json.loads(result.stdout)
	except ValueError:
		return None


def normalize(title: str) -> str:
	"""Compare titles ignoring case, punctuation and typographic variants."""
	title = title.replace("’", "'").replace("‑", "-").replace("\xa0", " ")
	title = unicodedata.normalize("NFKD", title).encode("ascii", "ignore").decode()
	return re.sub(r"[^a-z0-9]+", " ", title.lower()).strip()


def slugify(text: str) -> str:
	text = text.replace("&", " and ").replace("‑", "-")
	text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
	return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def split_camel(text: str) -> str:
	return re.sub(r"(?<=[a-z])(?=[A-Z])", " ", text)


def current_build() -> str:
	return subprocess.run(["sw_vers", "-buildVersion"], capture_output=True, text=True).stdout.strip()


def pane_file(group: str, pane: list[str]) -> Path:
	return INVENTORY_DIR.joinpath(group, *[slugify(p) for p in pane[:-1]], slugify(pane[-1]) + ".json")


# ---------------------------------------------------------------------------
# Inventory files
# ---------------------------------------------------------------------------

def load_all() -> dict[Path, dict]:
	files = {}
	for path in sorted(INVENTORY_DIR.rglob("*.json")):
		with open(path, encoding="utf-8") as f:
			files[path] = json.load(f)
	return files


def load_or_create(files: dict[Path, dict], group: str, pane: list[str]) -> dict:
	path = pane_file(group, pane)
	if path not in files:
		files[path] = {"group": group, "pane": pane, "coverage": "", "settings": {}}
	return files[path]


def save_all(files: dict[Path, dict]):
	for path, data in files.items():
		path.parent.mkdir(parents=True, exist_ok=True)
		with open(path, "w", encoding="utf-8") as f:
			json.dump(data, f, indent="\t", sort_keys=True, ensure_ascii=False)
			f.write("\n")


def status_of(setting: dict) -> str:
	if setting.get("skip"):
		return "skipped"
	if setting.get("option") and setting.get("verified"):
		return "verified"
	if setting.get("option"):
		return "implemented"
	if setting.get("storage"):
		return "mapped"
	return "todo"


def pane_label(data: dict) -> str:
	return " > ".join(data["pane"])


# ---------------------------------------------------------------------------
# extract: discover settings on this Mac
# ---------------------------------------------------------------------------

class Localizer:
	"""Resolves App Intents localisation keys through a bundle's English .loctable files."""

	def __init__(self, bundle: str):
		self.resources = os.path.join(bundle, "Contents", "Resources")
		self.tables: dict[str, dict] = {}

	def table(self, name: str) -> dict:
		if name not in self.tables:
			self.tables[name] = plist_json(os.path.join(self.resources, name + ".loctable"), "en") or {}
		return self.tables[name]

	def __call__(self, string: dict | None) -> str:
		if not string:
			return ""
		key = string.get("key", "")
		value = self.table(string.get("table") or "Localizable").get(key)
		if isinstance(value, dict):  # plural / variant rule, take any form
			value = next((v for v in value.values() if isinstance(v, str)), None)
		return value or key


def discover_panes() -> dict[str, dict]:
	"""Every System Settings pane, keyed by bundle id, with its sidebar path."""
	panes = {}
	for appex in glob.glob(os.path.join(EXTENSIONS_DIR, "*.appex")):
		info = plist_json(os.path.join(appex, "Contents", "Info.plist")) or {}
		attributes = info.get("EXAppExtensionAttributes", {})
		if attributes.get("EXExtensionPointIdentifier") != SETTINGS_EXTENSION_POINT:
			continue
		bundle_id = info["CFBundleIdentifier"]
		localized = plist_json(os.path.join(appex, "Contents", "Resources", "InfoPlist.loctable"), "en") or {}
		name = (
			PANE_NAME_OVERRIDES.get(bundle_id)
			or localized.get("CFBundleDisplayName")
			or info.get("CFBundleDisplayName")
			or info.get("CFBundleName")
		)
		settings_attributes = attributes.get("SettingsExtensionAttributes", {})
		panes[bundle_id] = {
			"name": name.replace("\xa0", " "),
			"appex": appex,
			"hosted": settings_attributes.get("hosted_bundles", []),
			"searchTerms": settings_attributes.get("searchTermsFileName"),
		}

	parents = {child: parent for parent, pane in panes.items() for child in pane["hosted"]}
	for bundle_id, pane in panes.items():
		parent = parents.get(bundle_id)
		pane["path"] = ([panes[parent]["name"]] if parent else []) + [pane["name"]]
	return panes


def intent_candidates(metadata_path: str, bundle: str) -> list[dict]:
	with open(metadata_path, encoding="utf-8") as f:
		metadata = json.load(f)
	localize = Localizer(bundle)
	enums = {e["identifier"]: e for e in metadata.get("enums", [])}
	bundle_name = os.path.basename(bundle)

	candidates = []
	for entity_name, entity in metadata.get("entities", {}).items():
		if entity_name in IGNORED_ENTITIES:
			continue
		properties = [p for p in entity.get("properties", []) if p.get("updateActionIdentifier")]
		entity_title = localize(entity.get("displayTypeName"))

		for prop in properties:
			single = len(properties) == 1 and prop["identifier"] == "value"
			title = re.sub(r"\s*Settings$", "", entity_title) if single else localize(prop.get("title"))
			section = None if single else re.sub(r"\s*Settings$", "", entity_title) or None
			if section and normalize(section) == normalize(title):
				section = None

			if bundle_name == "AccessibilitySettingsWidgetExtension.appex":
				key = entity.get("displayTypeName", {}).get("key", "")
				parts = key.split(".")
				if len(parts) > 1:
					section = ACCESSIBILITY_SECTIONS.get(parts[1], split_camel(parts[1]))

			value_type = prop.get("valueType", {})
			choices = []
			if "linkEnumeration" in value_type:
				kind = "enum"
				enum = enums.get(value_type["linkEnumeration"]["wrapper"]["identifier"], {})
				choices = [localize(case.get("displayRepresentation", {}).get("title")) for case in enum.get("cases", [])]
			elif "primitive" in value_type:
				kind = PRIMITIVE_KINDS.get(value_type["primitive"]["wrapper"].get("typeIdentifier"), "unknown")
			else:
				kind = "unknown"

			candidates.append({
				"source": f"intent:{bundle_name}/{entity_name}.{prop['identifier']}",
				"title": title,
				"section": section,
				"kind": kind,
				"choices": choices,
			})
	return candidates


def search_term_candidates(pane: dict) -> list[dict]:
	name = pane["searchTerms"]
	resources = os.path.join(pane["appex"], "Contents", "Resources")
	for lproj in ("en.lproj", "Base.lproj"):
		path = os.path.join(resources, lproj, name + ".searchTerms")
		if os.path.exists(path):
			break
	else:
		return []

	terms = plist_json(path) or {}
	appex = os.path.basename(pane["appex"])
	candidates = []
	for section, entries in terms.items():
		for entry in (entries or {}).get("localizableStrings", []):
			title = entry.get("title", "").strip()
			if not title:
				continue
			candidates.append({
				"source": f"search:{appex}/{section}/{title}",
				"title": title,
				"section": split_camel(section[:1].upper() + section[1:]) if normalize(section) != normalize(pane["name"]) else None,
				"kind": "unknown",
				"choices": [],
			})
	return candidates


def merge_candidate(data: dict, candidate: dict, build: str):
	settings = data["settings"]
	source = candidate["source"]

	# 1. same source seen before
	setting = next((s for s in settings.values() if source in s.get("sources", [])), None)

	# 2. same setting described by another source (e.g. intent + search term)
	if setting is None:
		wanted = normalize(candidate["title"])
		setting = next(
			(s for s in settings.values()
			 if normalize(s["title"]) == wanted
			 and not any(src.split(":")[0] == source.split(":")[0] for src in s.get("sources", []))),
			None,
		)

	if setting is None:
		base = slugify(" ".join(filter(None, [candidate["section"], candidate["title"]]))) or "setting"
		setting_id, n = base, 2
		while setting_id in settings:
			setting_id, n = f"{base}-{n}", n + 1
		setting = settings[setting_id] = {"title": candidate["title"], "sources": [], "firstSeen": build}

	if source not in setting["sources"]:
		setting["sources"] = sorted(setting["sources"] + [source])
	setting["lastSeen"] = build

	# intents and the UI know more than search terms; never let a vaguer source overwrite
	if source.startswith(("intent:", "ui:")) or setting.get("kind", "unknown") == "unknown":
		setting["title"] = candidate["title"]
		if candidate["section"]:
			setting["section"] = candidate["section"]
		setting["kind"] = candidate["kind"]
		if candidate["choices"]:
			setting["choices"] = candidate["choices"]


def cmd_extract(args):
	if sys.platform != "darwin":
		sys.exit("extract has to run on macOS")

	build = current_build()
	files = load_all()
	panes = discover_panes()
	counts: Counter = Counter()

	for pane in panes.values():
		data = load_or_create(files, "system-settings", pane["path"])
		if pane["searchTerms"]:
			for candidate in search_term_candidates(pane):
				merge_candidate(data, candidate, build)
				counts["search terms"] += 1

	metadata_files = (
		glob.glob(os.path.join(EXTENSIONS_DIR, "*.appex/Contents/Resources/Metadata.appintents/extract.actionsdata"))
		+ glob.glob(os.path.join(APPLICATIONS_DIR, "*.app/Contents/Resources/Metadata.appintents/extract.actionsdata"))
		+ glob.glob(os.path.join(APPLICATIONS_DIR, "*.app/Contents/PlugIns/*.appex/Contents/Resources/Metadata.appintents/extract.actionsdata"))
	)
	unmapped = []
	for metadata_path in sorted(metadata_files):
		bundle = metadata_path.split("/Contents/Resources/")[0]
		candidates = intent_candidates(metadata_path, bundle)
		if not candidates:
			continue

		bundle_name = os.path.basename(bundle)
		if bundle.startswith(APPLICATIONS_DIR):
			app = bundle[len(APPLICATIONS_DIR) + 1:].split(".app/")[0].removesuffix(".app")
			data = load_or_create(files, "applications", [app])
		elif bundle_name in INTENT_BUNDLE_PANES:
			data = load_or_create(files, "system-settings", INTENT_BUNDLE_PANES[bundle_name])
		else:
			unmapped.append(bundle_name)
			continue

		for candidate in candidates:
			merge_candidate(data, candidate, build)
			counts["intents"] += 1

	for data in files.values():
		if data["group"] == "system-settings" and not data["coverage"]:
			has_intents = any(src.startswith("intent:") for s in data["settings"].values() for src in s["sources"])
			has_search = any(src.startswith("search:") for s in data["settings"].values() for src in s["sources"])
			data["coverage"] = (
				"intents" if has_intents else "search-terms" if has_search else "none"
			)

	save_all(files)
	print(f"build {build}: merged {counts['intents']} intent and {counts['search terms']} search-term entries into {len(files)} files")
	for name in unmapped:
		print(f"  skipped {name}: add it to INTENT_BUNDLE_PANES if it describes a settings pane")


# ---------------------------------------------------------------------------
# sync: check off implemented settings
# ---------------------------------------------------------------------------

def load_option_index(index_file: str | None) -> list[dict]:
	if index_file:
		with open(index_file, encoding="utf-8") as f:
			return json.load(f)
	result = subprocess.run(
		["nix", "eval", "--json", f"path:{ROOT}#optionIndex"],
		capture_output=True, text=True,
	)
	if result.returncode != 0:
		sys.exit(f"nix eval .#optionIndex failed:\n{result.stderr}")
	return json.loads(result.stdout)


def option_pane(option: dict) -> tuple[str, list[str], list[str]]:
	"""(group, pane path, remaining UI path) for an option, derived from its UI path."""
	path = list(option["path"])
	if option["option"].startswith("applications.systemSettings."):
		if path[0] in ("System Settings", "System"):
			path = path[1:]
		head = OPTION_PANE_ALIASES.get(path[0], [path[0]])
		rest = path[1:]
		if head == ["General"] and rest:
			head, rest = ["General", rest[0]], rest[1:]
		return "system-settings", head, rest
	return "applications", [path[0]], path[1:]


GLOBAL_DOMAIN_NAMES = {"NSGlobalDomain", "-g", "-globalDomain", ".GlobalPreferences"}


def normalize_domain(domain: str) -> str:
	"""`defaults` accepts a domain as a name or as a plist path; compare them by name."""
	name = domain.rsplit("/", 1)[-1]
	name = re.sub(r"\.plist$", "", name)
	return "NSGlobalDomain" if name in GLOBAL_DOMAIN_NAMES else name


def storage_from_commands(commands: dict) -> list[dict]:
	"""Where an option's commands keep its value. Deletes only count for keys the option never
	writes, so clearing a stale copy elsewhere (e.g. in ByHost) isn't mistaken for storage."""
	pattern = r"/usr/bin/defaults (?:(-currentHost) )?(write|delete) (\S+) \"([^\"]+)\"(?: -(\w+))?"
	operations = [
		(action, normalize_domain(domain), key, bool(current_host) or "/ByHost/" in domain,
		 "system" if domain.startswith("/Library/") else "user", value_type)
		for command in commands.values()
		for current_host, action, domain, key, value_type in re.findall(pattern, command)
	]
	written_keys = {key for action, _, key, *_ in operations if action == "write"}

	storage = {}
	for action, domain, key, by_host, scope, value_type in operations:
		if action == "delete" and key in written_keys:
			continue
		entry = storage.setdefault((domain, key, by_host), {
			"domain": domain, "key": key, "byHost": by_host, "scope": scope,
		})
		if value_type:
			entry["type"] = value_type
	return sorted(storage.values(), key=lambda s: (s["domain"], s["key"]))


def find_option_match(data: dict, option: dict, title: str, rest: list[str]) -> dict | None:
	"""The unclaimed discovered setting an option implements, if exactly one fits."""
	# "Widgets > Show widgets > On Desktop" should match "Show Widgets On Desktop"
	wanted = {normalize(title)} | {normalize(" ".join(rest[i:])) for i in range(len(rest))}
	candidates = [
		s for s in data["settings"].values()
		if not s.get("option") and normalize(s["title"]) in wanted
	]
	if len(candidates) > 1:
		# tie-break on the option's attribute path, e.g. notifications.notificationCenter.showPreviews
		words = normalize(split_camel(option["option"].replace(".", " ")))
		candidates = [s for s in candidates if s.get("section") and normalize(s["section"]) in words]
	return candidates[0] if len(candidates) == 1 else None


def commands_digest(option: dict) -> str:
	"""Identifies what an option does, so a verification can tell when it went stale."""
	encoded = json.dumps(option["commands"], sort_keys=True).encode()
	return hashlib.sha256(encoded).hexdigest()[:12]


def cmd_sync(args):
	options = load_option_index(args.index)
	known = {o["option"] for o in options}
	files = load_all()
	build = current_build() if sys.platform == "darwin" else ""

	# options that disappeared from lib/options
	for data in files.values():
		for setting in data["settings"].values():
			if setting.get("option") and setting["option"] not in known:
				print(f"  {pane_label(data)}: {setting['option']} no longer exists, unlinking")
				setting.pop("option")
				setting.pop("verified", None)

	by_option = {s["option"]: s for data in files.values() for s in data["settings"].values() if s.get("option")}
	added = linked = invalidated = 0
	for option in options:
		name = option["option"]
		setting = by_option.get(name)
		if setting is None:
			group, pane, rest = option_pane(option)
			data = load_or_create(files, group, pane)
			title = rest[-1] if rest else pane[-1]
			section = " > ".join(rest[:-1]) or None

			setting = find_option_match(data, option, title, rest)
			if setting is not None:
				linked += 1
			else:
				setting_id = slugify(" ".join(rest) or title)
				setting = data["settings"].setdefault(setting_id, {
					"title": title, "section": section, "kind": "unknown",
					"sources": [], "firstSeen": build, "lastSeen": build,
				})
				added += 1
			setting["option"] = name
			setting["sources"] = sorted(set(setting.get("sources", [])) | {f"option:{name}"})

		setting["storage"] = storage_from_commands(option["commands"]) or setting.get("storage", [])
		# a verification only holds for the commands that were verified
		if setting.get("verified") and setting["verified"].get("commands") != commands_digest(option):
			setting.pop("verified")
			invalidated += 1

	save_all(files)
	print(f"linked {linked} options to discovered settings, added {added} settings only known from options")
	if invalidated:
		print(f"{invalidated} options changed since they were verified; verify them again")


# ---------------------------------------------------------------------------
# report / check / todo
# ---------------------------------------------------------------------------

def render_report(files: dict[Path, dict]) -> str:
	totals: Counter = Counter()
	rows = []
	details = []

	ordered = sorted(files.values(), key=lambda d: (d["group"], [p.lower() for p in d["pane"]]))
	for data in ordered:
		counts = Counter(status_of(s) for s in data["settings"].values())
		totals.update(counts)
		total = sum(counts.values())
		done = counts["verified"] + counts["implemented"]
		relevant = total - counts["skipped"]
		percent = f"{round(100 * done / relevant)}%" if relevant else "–"
		rows.append(
			f"| {data['group']} | {pane_label(data)} | {data.get('coverage') or '–'} | {total} "
			f"| {counts['verified']} | {counts['implemented']} | {counts['mapped']} | {counts['todo']} "
			f"| {counts['skipped']} | {percent} |"
		)

		if not data["settings"]:
			continue
		lines = [f"<details>\n<summary><b>{pane_label(data)}</b> ({done}/{relevant})</summary>\n"]
		for setting in sorted(data["settings"].values(), key=lambda s: ((s.get("section") or ""), s["title"].lower())):
			status = status_of(setting)
			box = "x" if status in ("verified", "implemented") else " "
			label = " > ".join(filter(None, [setting.get("section"), setting["title"]]))
			extra = {
				"verified": f"`{setting.get('option')}` verified on {setting['verified'].get('build', '?')}" if setting.get("verified") else "",
				"implemented": f"`{setting.get('option')}`",
				"mapped": ", ".join(f"`{s['domain']} {s['key']}`" for s in setting.get("storage", [])),
				"skipped": f"skipped: {setting.get('skip')}",
				"todo": "",
			}[status]
			lines.append(f"- [{box}] {label}" + (f" — {extra}" if extra else ""))
		lines.append("\n</details>\n")
		details.append("\n".join(lines))

	total = sum(totals.values())
	relevant = total - totals["skipped"]
	done = totals["verified"] + totals["implemented"]
	summary = (
		f"**{done} of {relevant}** settings implemented "
		f"({totals['verified']} verified, {totals['implemented']} unverified), "
		f"{totals['mapped']} mapped but not implemented, {totals['todo']} to do, {totals['skipped']} skipped."
	)

	return "\n".join([
		"# Coverage",
		"",
		"<!-- Generated by `tools/inventory/inventory.py report`. Do not edit by hand. -->",
		"",
		summary,
		"",
		"Statuses: **verified** (option confirmed working on a macOS build) · **implemented** (option exists) · "
		"**mapped** (storage known, no option yet) · **todo** · **skipped** (not plist-backed or not a setting).",
		"",
		"Coverage source: **intents** (typed settings from App Intents metadata) · **search-terms** "
		"(titles from the pane's search index) · **none** (walk the pane by hand).",
		"",
		"| Group | Pane | Source | Settings | Verified | Implemented | Mapped | Todo | Skipped | Done |",
		"| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
		*rows,
		"",
		"## Settings",
		"",
		*details,
	])


def cmd_report(args):
	COVERAGE_FILE.write_text(render_report(load_all()), encoding="utf-8")
	print(f"wrote {COVERAGE_FILE.relative_to(ROOT)}")


def cmd_check(args):
	errors = []
	files = load_all()
	options = {o["option"] for o in load_option_index(args.index)} if not args.skip_options else None

	for path, data in files.items():
		where = path.relative_to(ROOT)
		if path != pane_file(data["group"], data["pane"]):
			errors.append(f"{where}: file name does not match pane {data['pane']}")
		for setting_id, setting in data["settings"].items():
			label = f"{where}:{setting_id}"
			for field in set(setting) - SETTING_FIELDS:
				errors.append(f"{label}: unknown field '{field}'")
			if setting.get("kind", "unknown") not in KINDS:
				errors.append(f"{label}: kind must be one of {KINDS}")
			for storage in setting.get("storage", []):
				if not {"domain", "key"} <= set(storage) or set(storage) - STORAGE_FIELDS:
					errors.append(f"{label}: storage entries need domain and key, and only {sorted(STORAGE_FIELDS)}")
			ui = setting.get("ui")
			if ui is not None and not (isinstance(ui.get("pane"), str) and isinstance(ui.get("expect"), dict)):
				errors.append(f"{label}: ui needs a pane and an expect table (see tools/verify/verify.py)")
			if setting.get("verified") and not setting.get("option"):
				errors.append(f"{label}: verified without an option")
			if options is not None and setting.get("option") and setting["option"] not in options:
				errors.append(f"{label}: option {setting['option']} does not exist")

	if COVERAGE_FILE.exists() and COVERAGE_FILE.read_text(encoding="utf-8") != render_report(files):
		errors.append("inventory/COVERAGE.md is stale, run `inventory.py report`")

	for error in errors:
		print(error)
	if errors:
		sys.exit(1)
	print(f"ok: {sum(len(d['settings']) for d in files.values())} settings in {len(files)} files")


def find_setting(files: dict[Path, dict], ref: str) -> tuple[dict, str]:
	"""Resolve `path/to/pane.json#setting-id` (path relative to the repo)."""
	file, _, setting_id = ref.partition("#")
	path = (ROOT / file).resolve()
	if path not in files or setting_id not in files[path]["settings"]:
		sys.exit(f"no setting {ref}")
	return files[path], setting_id


def cmd_link(args):
	files = load_all()
	data, setting_id = find_setting(files, args.setting)
	setting = data["settings"][setting_id]

	# fold in the entry sync created for this option, if any
	for other in files.values():
		for other_id, entry in list(other["settings"].items()):
			if entry is setting or entry.get("option") != args.option:
				continue
			if any(not src.startswith("option:") for src in entry.get("sources", [])):
				sys.exit(f"{args.option} is already linked to {pane_label(other)} :: {entry['title']}")
			for field in ("storage", "verified", "notes"):
				if entry.get(field) and not setting.get(field):
					setting[field] = entry[field]
			del other["settings"][other_id]

	setting["option"] = args.option
	setting["sources"] = sorted(set(setting.get("sources", [])) | {f"option:{args.option}"})
	save_all(files)
	print(f"linked {args.option} to {pane_label(data)} :: {setting['title']}")


def cmd_merge(args):
	"""Fold a duplicate entry (e.g. the same setting found by two sources under different titles)
	into another, keeping the target's title."""
	files = load_all()
	source_data, source_id = find_setting(files, args.duplicate)
	target_data, target_id = find_setting(files, args.into)
	duplicate = source_data["settings"].pop(source_id)
	target = target_data["settings"][target_id]
	if duplicate.get("option") and target.get("option") and duplicate["option"] != target["option"]:
		sys.exit(f"both entries have an option ({duplicate['option']}, {target['option']}); unlink one first")
	target["sources"] = sorted(set(target.get("sources", [])) | set(duplicate.get("sources", [])))
	for field in ("option", "storage", "verified", "ui", "notes", "choices"):
		if duplicate.get(field) and not target.get(field):
			target[field] = duplicate[field]
	if target.get("kind", "unknown") == "unknown":
		target["kind"] = duplicate.get("kind", "unknown")
	target["firstSeen"] = min(filter(None, [target.get("firstSeen"), duplicate.get("firstSeen")]), default="")
	save_all(files)
	print(f"merged {pane_label(source_data)} :: {duplicate['title']} into {target['title']}")


def cmd_skip(args):
	files = load_all()
	data, setting_id = find_setting(files, args.setting)
	data["settings"][setting_id]["skip"] = args.reason
	save_all(files)


def cmd_todo(args):
	for path, data in sorted(load_all().items()):
		if args.pane and normalize(args.pane) not in normalize(pane_label(data)):
			continue
		for setting_id, setting in sorted(data["settings"].items()):
			status = status_of(setting)
			if args.status and status != args.status:
				continue
			label = " > ".join(filter(None, [setting.get("section"), setting["title"]]))
			print(f"{status:12} {pane_label(data)} :: {label}  [{path.relative_to(ROOT)}#{setting_id}]")


def main():
	parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
	sub = parser.add_subparsers(dest="command", required=True)

	sub.add_parser("extract", help="scan this Mac and merge settings into the inventory")

	sync = sub.add_parser("sync", help="check off settings implemented by an option")
	sync.add_argument("--index", help="use an optionIndex JSON file instead of running nix eval")

	link = sub.add_parser("link", help="link an option to a discovered setting by hand")
	link.add_argument("setting", help="inventory/<group>/<pane>.json#<setting-id>")
	link.add_argument("option", help="option path, e.g. applications.systemSettings.desktopAndDock.dock.size")

	merge = sub.add_parser("merge", help="fold a duplicate entry into another")
	merge.add_argument("duplicate", help="inventory/<group>/<pane>.json#<setting-id> to remove")
	merge.add_argument("into", help="inventory/<group>/<pane>.json#<setting-id> to keep")

	skip = sub.add_parser("skip", help="mark a setting as not worth an option")
	skip.add_argument("setting", help="inventory/<group>/<pane>.json#<setting-id>")
	skip.add_argument("reason")

	sub.add_parser("report", help="regenerate inventory/COVERAGE.md")

	check = sub.add_parser("check", help="validate the inventory (for CI)")
	check.add_argument("--index", help="use an optionIndex JSON file instead of running nix eval")
	check.add_argument("--skip-options", action="store_true", help="don't check option names against the flake")

	todo = sub.add_parser("todo", help="list settings")
	todo.add_argument("--pane", help="only panes whose name contains this")
	todo.add_argument("--status", choices=STATUSES)

	args = parser.parse_args()
	{"extract": cmd_extract, "sync": cmd_sync, "report": cmd_report, "check": cmd_check, "todo": cmd_todo, "link": cmd_link,
	 "merge": cmd_merge, "skip": cmd_skip}[args.command](args)


if __name__ == "__main__":
	main()
