#!/usr/bin/env python3
"""
wallpapers — write the catalog of the wallpapers macOS comes with, for applications.systemSettings.wallpaper.

    python3 tools/wallpapers.py > lib/options/applications/systemSettings/wallpapers.json

Run it on each new macOS release, after opening Wallpaper in System Settings once so macOS has
fetched its catalogs.
"""

import json
import plistlib
import subprocess
from pathlib import Path

EXTENSIONS = Path("/System/Library/ExtensionKit/Extensions")
AERIALS = EXTENSIONS / "WallpaperAerialsExtension.appex/Contents/Resources/entries.json"
TAHOE = EXTENSIONS / "NeptuneOneWallpaper.appex/Contents/Resources/manifest.json"
AERIAL_NAMES = Path.home() / "Library/Application Support/com.apple.wallpaper/aerials/manifest/TVIdleScreenStrings.bundle/Contents/Resources/Localizable.nocache.loctable"
ASSETS = Path("/System/Library/AssetsV2/com_apple_MobileAsset_DesktopPicture/com_apple_MobileAsset_DesktopPicture.xml")
PICTURES = Path("/System/Library/Desktop Pictures")

AERIAL_CATEGORIES = {
	"AerialCategoryLandscapes": "Landscape",
	"AerialCategoryCities": "Cityscape",
	"AerialCategoryUnderwater": "Underwater",
	"AerialCategorySpace": "Earth",
	"AerialCategoryMac": "Mac",
}
# System Settings names these after the release rather than the file
SHOWN_AS = {"Ventura Graphic": "Ventura", "Monterey Graphic": "Monterey"}
# the heic files that belong to a dynamic wallpaper rather than to Pictures
DYNAMIC_FILES = {"Sonoma"}

aerials_catalog = json.loads(AERIALS.read_text())
names = json.loads(subprocess.run(["plutil", "-convert", "json", "-o", "-", str(AERIAL_NAMES)], capture_output=True, check=True).stdout)["en"]
categories = {c["id"]: AERIAL_CATEGORIES.get(c.get("localizedNameKey")) for c in aerials_catalog["categories"]}

aerials = {}
golden_gate = {}
for asset in aerials_catalog["assets"]:
	category = categories.get(asset["categories"][0])
	if category and asset.get("localizedNameKey") in names:
		aerials[names[asset["localizedNameKey"]]] = {"id": asset["id"], "url": asset["url-4K-SDR-240FPS"], "category": category}
	if "dynamic-aerials" in asset["categories"] and asset.get("variant", {}).get("orientation") == "landscape":
		golden_gate[asset["variant"]["appearance"]] = {"id": asset["id"], "url": asset["url-4K-SDR-240FPS"]}

shuffles = {"Shuffle All": "shuffle-all-aerials"}
shuffles |= {f"Shuffle {name}": id for id, name in categories.items() if name and name != "Mac"}

tahoe = {key.removesuffix("RemoteURL"): url for key, url in json.loads(TAHOE.read_text()).items() if key.endswith("RemoteURL")}

downloads = {
	asset["DesktopPictureID"]: asset["__BaseURL"] + asset["__RelativePath"]
	for asset in plistlib.loads(ASSETS.read_bytes())["Assets"]
}

pictures, dynamic = {}, {}
for described in sorted(PICTURES.glob("*.madesktop")):
	about = plistlib.loads(described.read_bytes())
	name = SHOWN_AS.get(described.stem, described.stem)
	entry = {"file": described.stem, "asset": about["mobileAssetID"], "url": downloads[about["mobileAssetID"]]}
	if about.get("isDynamic"):
		dynamic[name] = entry | {"solar": about.get("isSolar", False)}
	else:
		pictures[name] = entry


def readable(path):
	return "pixelWidth" in subprocess.run(["sips", "-g", "pixelWidth", str(path)], capture_output=True, text=True).stdout


for image in sorted(PICTURES.glob("*.heic")):
	if image.stem not in DYNAMIC_FILES and image.stem not in pictures and readable(image):
		pictures[image.stem] = {"file": image.stem}

print(json.dumps({
	"aerials": aerials, "goldenGate": golden_gate, "shuffles": shuffles, "tahoe": tahoe,
	"dynamic": dynamic, "pictures": pictures,
}, indent="\t", sort_keys=True, ensure_ascii=False))
