#!/usr/bin/env python3
"""
capture — save state arranged in System Settings for a snapshot setting.

    nix run .#capture -- <option> <directory>
    nix run .#capture -- applications.systemSettings.menuBar.layout ./menu-bar

Writes one XML plist per storage entry of the option (a whole domain, or one key) to
<directory>, and prints the line to put in your configuration. Arrange things in System
Settings, capture, commit the directory; each activation puts that state back.
"""

from __future__ import annotations

import json
import os
import plistlib
import subprocess
import sys
from pathlib import Path

ROOT = Path(os.environ.get("NIX_PLIST_MANAGER_ROOT") or Path(__file__).resolve().parents[1])


def export(entry: dict) -> dict:
	domain = entry["domain"]
	if domain.startswith("~/"):
		domain = str(Path.home() / domain[2:])
	host = ["-currentHost"] if entry.get("byHost") else []
	result = subprocess.run(["defaults", *host, "export", domain, "-"], capture_output=True)
	return plistlib.loads(result.stdout) if result.returncode == 0 and result.stdout else {}


def main():
	if len(sys.argv) != 3 or sys.argv[1] in ("-h", "--help"):
		sys.exit(__doc__.strip())
	option, directory = sys.argv[1], Path(sys.argv[2])

	result = subprocess.run(["nix", "eval", "--json", f"path:{ROOT}#optionIndex"], capture_output=True, text=True)
	if result.returncode != 0:
		sys.exit(f"nix eval .#optionIndex failed:\n{result.stderr}")
	entry = next((o for o in json.loads(result.stdout) if o["option"] == option), None)
	if entry is None:
		sys.exit(f"no option {option}")
	if entry.get("kind") != "snapshot":
		sys.exit(f"{option} isn't a snapshot setting; set it in your configuration instead")

	directory.mkdir(parents=True, exist_ok=True)
	for storage in entry["storage"]:
		values = export(storage)
		if storage["key"] is not None:
			values = {storage["key"]: values[storage["key"]]} if storage["key"] in values else {}
		path = directory / f"{storage['as']}.plist"
		with open(path, "wb") as f:
			plistlib.dump(values, f, fmt=plistlib.FMT_XML, sort_keys=True)
		print(f"wrote {path} ({len(values)} keys)", file=sys.stderr)

	relative = os.path.relpath(directory)
	path = f"./{relative}" if not relative.startswith("..") else str(directory.resolve())
	print(f"programs.nix-plist-manager.options.{option} = {path};")


if __name__ == "__main__":
	main()
