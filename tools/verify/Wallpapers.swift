import Foundation
import ImageIO

// The catalog of the wallpapers macOS comes with, for applications.systemSettings.wallpaper. Run it after
// opening Wallpaper in System Settings once, so macOS has fetched its catalogs.
func wallpapers() throws {
	let extensions = "/System/Library/ExtensionKit/Extensions"
	let pictures = "/System/Library/Desktop Pictures"
	let plist = { (path: String) throws -> [String: Any] in
		try PropertyListSerialization.propertyList(from: try Data(contentsOf: URL(fileURLWithPath: path)), format: nil) as! [String: Any]
	}
	let jsonFile = { (path: String) throws -> [String: Any] in try parseJSON(try Data(contentsOf: URL(fileURLWithPath: path))) as! [String: Any] }

	let aerialsCatalog = try jsonFile("\(extensions)/WallpaperAerialsExtension.appex/Contents/Resources/entries.json")
	let names = try plist(NSHomeDirectory() + "/Library/Application Support/com.apple.wallpaper/aerials/manifest/TVIdleScreenStrings.bundle/Contents/Resources/Localizable.nocache.loctable")["en"] as! [String: String]
	let categoryNames = [
		"AerialCategoryLandscapes": "Landscape", "AerialCategoryCities": "Cityscape", "AerialCategoryUnderwater": "Underwater",
		"AerialCategorySpace": "Earth", "AerialCategoryMac": "Mac",
	]
	var categories: [String: String] = [:]
	for category in aerialsCatalog["categories"] as! [[String: Any]] {
		if let key = category["localizedNameKey"] as? String, let name = categoryNames[key] { categories[category["id"] as! String] = name }
	}

	var aerials: [String: Any] = [:], goldenGate: [String: Any] = [:]
	for asset in aerialsCatalog["assets"] as! [[String: Any]] {
		let assetCategories = asset["categories"] as? [String] ?? []
		let url = asset["url-4K-SDR-240FPS"] as? String ?? ""
		if let category = assetCategories.first.flatMap({ categories[$0] }), let key = asset["localizedNameKey"] as? String, let name = names[key] {
			aerials[name] = ["id": asset["id"]!, "url": url, "category": category]
		}
		if assetCategories.contains("dynamic-aerials"), let variant = asset["variant"] as? [String: Any], variant["orientation"] as? String == "landscape" {
			goldenGate[variant["appearance"] as! String] = ["id": asset["id"]!, "url": url]
		}
	}

	var shuffles: [String: Any] = ["Shuffle All": "shuffle-all-aerials"]
	for (id, name) in categories where name != "Mac" { shuffles["Shuffle \(name)"] = id }

	var tahoe: [String: Any] = [:]
	for (key, url) in try jsonFile("\(extensions)/NeptuneOneWallpaper.appex/Contents/Resources/manifest.json") where key.hasSuffix("RemoteURL") {
		tahoe[String(key.dropLast("RemoteURL".count))] = url
	}

	var downloads: [String: String] = [:]
	for asset in try plist("/System/Library/AssetsV2/com_apple_MobileAsset_DesktopPicture/com_apple_MobileAsset_DesktopPicture.xml")["Assets"] as! [[String: Any]] {
		downloads[asset["DesktopPictureID"] as! String] = (asset["__BaseURL"] as! String) + (asset["__RelativePath"] as! String)
	}

	// System Settings names these after the release rather than the file
	let shownAs = ["Ventura Graphic": "Ventura", "Monterey Graphic": "Monterey"]
	// the heic files that belong to a dynamic wallpaper rather than to Pictures
	let dynamicFiles: Set<String> = ["Sonoma"]
	let files = try FileManager.default.contentsOfDirectory(atPath: pictures).sorted()
	var still: [String: Any] = [:], dynamic: [String: Any] = [:]
	for file in files where file.hasSuffix(".madesktop") {
		let stem = String(file.dropLast(".madesktop".count))
		let about = try plist("\(pictures)/\(file)")
		let asset = about["mobileAssetID"] as! String
		let entry: [String: Any] = ["file": stem, "asset": asset, "url": downloads[asset]!]
		if truthy(about["isDynamic"]) {
			dynamic[shownAs[stem] ?? stem] = entry.merging(["solar": truthy(about["isSolar"])]) { a, _ in a }
		} else {
			still[shownAs[stem] ?? stem] = entry
		}
	}
	for file in files where file.hasSuffix(".heic") {
		let stem = String(file.dropLast(".heic".count))
		guard !dynamicFiles.contains(stem), still[stem] == nil,
		      let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: "\(pictures)/\(file)") as CFURL, nil),
		      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any], properties["PixelWidth"] != nil else { continue }
		still[stem] = ["file": stem]
	}

	print(json([
		"aerials": aerials, "goldenGate": goldenGate, "shuffles": shuffles, "tahoe": tahoe, "dynamic": dynamic, "pictures": still,
	] as [String: Any], indent: "\t"))
}
