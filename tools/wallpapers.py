#!/usr/bin/env python3
"""
wallpapers — write the catalog of the wallpapers macOS comes with, for applications.systemSettings.wallpaper.

    python3 tools/wallpapers.py > lib/options/applications/systemSettings/wallpapers.json

Run it on each new macOS release: aerials are read from the aerials extension's catalog, pictures
from the ones installed in /System/Library/Desktop Pictures.
"""

import json
import subprocess
from pathlib import Path

CATALOG = Path("/System/Library/ExtensionKit/Extensions/WallpaperAerialsExtension.appex/Contents/Resources/entries.json")
NAMES = Path.home() / "Library/Application Support/com.apple.wallpaper/aerials/manifest/TVIdleScreenStrings.bundle/Contents/Resources/Localizable.nocache.loctable"
PICTURES = Path("/System/Library/Desktop Pictures")
# the names System Settings shows for the catalog's categories
CATEGORIES = {
	"AerialCategoryLandscapes": "Landscape",
	"AerialCategoryCities": "Cityscape",
	"AerialCategoryUnderwater": "Underwater",
	"AerialCategorySpace": "Earth",
	"AerialCategoryMac": "Mac",
}

catalog = json.loads(CATALOG.read_text())
# the English names System Settings shows, which WallpaperAgent downloads with the aerials
names = json.loads(subprocess.run(["plutil", "-convert", "json", "-o", "-", str(NAMES)], capture_output=True, check=True).stdout)["en"]
category_names = {c["id"]: CATEGORIES.get(c.get("localizedNameKey")) for c in catalog["categories"]}

aerials = {}
for asset in catalog["assets"]:
	category = category_names.get(asset["categories"][0])
	if category and asset.get("localizedNameKey") in names:
		aerials[names[asset["localizedNameKey"]]] = {"id": asset["id"], "url": asset["url-4K-SDR-240FPS"], "category": category}

dynamic = {}
for asset in catalog["assets"]:
	if "dynamic-aerials" in asset["categories"] and asset.get("variant", {}).get("orientation") == "landscape":
		for group in asset["subcategories"]:
			dynamic.setdefault(group, {})[asset["variant"]["appearance"]] = {"id": asset["id"], "url": asset["url-4K-SDR-240FPS"]}

shuffles = {"Shuffle All": "shuffle-all-aerials"}
shuffles |= {f"Shuffle {name}": id for id, name in category_names.items() if name and name != "Mac"}


def readable(path):
	return subprocess.run(["sips", "-g", "pixelWidth", str(path)], capture_output=True, text=True).stdout.count("pixelWidth") > 0


# Sonoma.heic belongs to the Sonoma dynamic wallpaper, not to Pictures
pictures = sorted(p.stem for p in PICTURES.glob("*.heic") if readable(p) and p.stem != "Sonoma")

print(json.dumps({"aerials": aerials, "dynamic": dynamic, "shuffles": shuffles, "pictures": pictures}, indent="\t", sort_keys=True, ensure_ascii=False))
