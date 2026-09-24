#!/usr/bin/env python3
"""
current — print this Mac's settings as nix-plist-manager options.

    nix run .#current -- [--scope user|system] [--against <file.nix>] [--only <prefix>] [--ui] [--snapshots <dir>] [--verbose]
    nix run .#capture -- <option> <directory>

--scope prints the options for home-manager (user) or nix-darwin (system) alone, ready to import.
--against prints only what differs from that file, e.g. after changing something in System Settings.
"""

from __future__ import annotations

import argparse
import base64
import concurrent.futures
import datetime
import json
import os
import plistlib
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = Path(os.environ.get("NIX_PLIST_MANAGER_ROOT") or HERE.parent)


def nix_eval(attribute: str, apply: str | None = None) -> object:
	command = ["nix", "eval", "--json", "--impure", f"path:{ROOT}#{attribute}"] + (["--apply", apply] if apply else [])
	result = subprocess.run(command, capture_output=True, text=True)
	if result.returncode != 0:
		sys.exit(f"nix eval .#{attribute} failed:\n{result.stderr}")
	return json.loads(result.stdout)


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


def as_json(value):
	if isinstance(value, dict):
		return {str(k): as_json(v) for k, v in value.items()}
	if isinstance(value, list):
		return [as_json(v) for v in value]
	if isinstance(value, bytes):
		return base64.b64encode(value).decode()
	if isinstance(value, datetime.datetime):
		return value.isoformat()
	if isinstance(value, int) and not isinstance(value, bool) and not -2**63 <= value < 2**63:
		return float(value)
	return value


def run_reader(command: str) -> dict:
	raw = subprocess.run(["/bin/bash", "-c", command], capture_output=True, text=True).stdout.strip()
	try:
		return {"raw": raw, "json": json.loads(raw)}
	except ValueError:
		return {"raw": raw}


def collect(options: list[dict]) -> dict:
	"""Every key the options store, and the output of every setting's own reader."""
	wanted: dict[tuple, set] = {}
	for entry in options:
		for key in entry["storage"]:
			if key["key"]:
				wanted.setdefault((key["domain"], key["byHost"], key["scope"]), set()).add(key["key"])
	domains = {}
	for (domain, by_host, scope), names in wanted.items():
		exported = export(domain, by_host, scope == "system")
		domains[f"{domain}|{str(by_host).lower()}|{scope}"] = {n: as_json(exported[n]) for n in names if n in exported}
	readers = {e["option"]: e["reads"]["command"] for e in options if e["reads"]}
	with concurrent.futures.ThreadPoolExecutor() as pool:
		reads = dict(zip(readers, pool.map(run_reader, readers.values())))
	return {"domains": domains, "reads": reads, "ui": {}, "snapshots": {}}


def capture(entry: dict, directory: Path):
	directory.mkdir(parents=True, exist_ok=True)
	for storage in entry["storage"]:
		values = export(storage["domain"], storage["byHost"])
		if storage["key"] is not None:
			values = {storage["key"]: values[storage["key"]]} if storage["key"] in values else {}
		path = directory / f"{storage['as']}.plist"
		path.write_bytes(plistlib.dumps(values, fmt=plistlib.FMT_XML, sort_keys=True))
		print(f"wrote {path} ({len(values)} keys)", file=sys.stderr)


def cmd_capture(option: str, directory: Path):
	entry = next((o for o in nix_eval("optionIndex") if o["option"] == option), None)
	if entry is None:
		sys.exit(f"no option {option}")
	if entry["kind"] != "snapshot":
		sys.exit(f"{option} isn't a snapshot setting; set it in your configuration instead")
	capture(entry, directory)
	relative = os.path.relpath(directory)
	path = f"./{relative}" if not relative.startswith("..") else str(directory.resolve())
	print(f"programs.nix-plist-manager.options.{option} = {path};")


def evaluate(state: dict, scope: str | None, against: str | None, only: str) -> dict:
	with tempfile.NamedTemporaryFile("w", suffix=".json") as file:
		json.dump(state, file)
		file.flush()
		args = [f"only = {json.dumps(only)};"] + ([f"scope = {json.dumps(scope)};"] if scope else [])
		if against:
			args.append(f"against = import {Path(against).resolve()};")
		return nix_eval("lib.current", f"f: f (builtins.fromJSON (builtins.readFile {file.name})) {{ {' '.join(args)} }}")


def main():
	if sys.argv[1:2] == ["capture"]:
		if len(sys.argv) != 4:
			sys.exit(__doc__.strip())
		return cmd_capture(sys.argv[2], Path(sys.argv[3]))

	parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
	parser.add_argument("--scope", choices=["user", "system"])
	parser.add_argument("--against", metavar="FILE")
	parser.add_argument("--only", metavar="PREFIX", default="", help="only options whose path starts with PREFIX")
	parser.add_argument("--ui", action="store_true", help="read what isn't stored from System Settings (opens it)")
	parser.add_argument("--snapshots", metavar="DIR", help="capture the snapshot options into DIR/<name>")
	parser.add_argument("--verbose", action="store_true", help="list the options that couldn't be read")
	args = parser.parse_args()

	options = [o for o in nix_eval("optionIndex") if o["option"].startswith(args.only)]
	if args.scope:
		options = [o for o in options if (o["module"] == "darwin") == (args.scope == "system")]
	state = collect(options)
	if args.snapshots:
		for entry in (o for o in options if o["kind"] == "snapshot"):
			directory = Path(args.snapshots).resolve() / entry["option"].rsplit(".", 1)[1]
			capture(entry, directory)
			state["snapshots"][entry["option"]] = str(directory)
	result = evaluate(state, args.scope, args.against, args.only)

	if args.ui:
		sys.path.insert(0, str(HERE))
		import verify  # noqa: E402
		index = {o["option"]: o for o in options}
		for missing in (m for m in result["unread"] if m["ui"]):
			value = verify.shown_values([index[missing["option"]]]).get(missing["option"])
			if value is not None:
				state["ui"][missing["option"]] = value
		result = evaluate(state, args.scope, args.against, args.only)

	print(result["text"])
	unread = [m for m in result["unread"] if not m["snapshot"]]
	summary = f"{result['read']} settings read"
	if args.against:
		summary += f", {result['changed']} differ from {args.against}"
	if unread:
		summary += f"; {len(unread)} {'has' if len(unread) == 1 else 'have'} nothing stored"
		readable = sum(m["ui"] for m in unread)
		if readable and not args.ui:
			summary += f" (--ui reads {readable} of them from System Settings)"
	snapshots = sum(m["snapshot"] for m in result["unread"])
	if snapshots:
		summary += f"; {snapshots} snapshots skipped (--snapshots)"
	print(summary, file=sys.stderr)
	if args.verbose:
		for missing in unread:
			print(f"  {missing['option']}", file=sys.stderr)


if __name__ == "__main__":
	main()
