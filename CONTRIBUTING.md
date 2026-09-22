# Contributing

nix-plist-manager keeps an inventory of every macOS setting it knows about and tracks which ones have an option. Pick a setting from the inventory, implement it, and check it off.

- [`inventory/COVERAGE.md`](inventory/COVERAGE.md) lists progress per pane and every setting with its status.
- `inventory/<group>/<pane>.json` holds the data, one file per System Settings pane or application.
- `tools/inventory/inventory.py` maintains it. Run it with `nix run .#inventory -- <command>` or `python3 tools/inventory/inventory.py <command>`.

## Where the list comes from

The inventory isn't written by hand. `extract` reads what macOS ships about its own settings:

- **App Intents metadata** (`*.appex/Contents/Resources/Metadata.appintents/extract.actionsdata`). This gives typed settings with their UI titles and, for pickers, the list of choices. These are recorded as `intent:` sources.
- **Settings search terms** (`<pane>.appex/Contents/Resources/en.lproj/*.searchTerms`). These are the titles the System Settings search box indexes. They have no type information. They're recorded as `search:` sources.

Panes whose `coverage` is `none` have neither source, so their settings have to be found by walking the pane by hand.

`sync` adds every option in `lib/options` that the extractor didn't find as an `option:` source. This covers things like Finder, hot corners and window tiling.

## A setting entry

```jsonc
"dock-size": {
	"title": "Size",                     // UI label
	"section": "Dock",                   // group within the pane, if any
	"kind": "number",                    // bool | number | string | enum | unknown
	"choices": [],                       // enum values, as the UI shows them
	"sources": ["intent:DesktopSettingsIntents.appex/DockSettingsEntity.size", "option:…"],
	"firstSeen": "26A428",               // macOS build it was first / last extracted from
	"lastSeen": "26A428",
	"storage": [                         // where the value lives
		{ "domain": "com.apple.dock", "key": "tilesize", "type": "int", "byHost": true, "scope": "user" }
	],
	"option": "applications.systemSettings.desktopAndDock.dock.size",
	"verified": { "build": "26A428", "date": "2026-09-22", "commands": "3f1c…" },
	"skip": "reason",                    // set instead of an option when it can't or shouldn't be one
	"notes": ""
}
```

The status is derived from these fields, not stored:

| Status | Meaning |
| --- | --- |
| **verified** | `option` and `verified` are set: the option was applied on the given build and System Settings showed the expected values. `commands` is a digest of the option's generated commands; `sync` drops the verification when they change. |
| **implemented** | `option` is set. |
| **mapped** | `storage` is known but there's no option yet. This is a good first contribution. |
| **todo** | Nothing is known yet. |
| **skipped** | `skip` explains why, e.g. "not stored in a plist", "duplicate of dock-size", "action, not a setting". |

## Workflows

### Implement a setting

1. Find one with `nix run .#inventory -- todo --status todo --pane Keyboard`, or look at `COVERAGE.md`.
2. Find where it's stored. Run `tools/watch.sh` (or `tools/plist-watcher.py --filter …`), flip the setting in System Settings and note the domain, key and type that change. Record them in `storage`, even if you stop here.
3. Add the option under `lib/options/…`. Its `path` should follow the UI labels, e.g. `[ "Desktop & Dock" "Dock" "Size" ]`.
4. Run `nix run .#inventory -- sync`. It links the option to the entry with the same title. If the title differs (the UI label and Apple's metadata sometimes disagree), link it yourself:
   ```sh
   nix run .#inventory -- link inventory/system-settings/keyboard.json#<setting-id> <option.path>
   ```
5. Add a `ui` spec and run `nix run .#verify -- check --setting <setting-id>` (see below), which marks the setting verified when System Settings shows every value the option sets.
6. Run `nix run .#inventory -- report` and commit the option, the inventory JSON and `COVERAGE.md` together.

New files have to be `git add`ed before `nix` can see them.

### Verify against the real UI

`tools/verify` drives System Settings through the Accessibility API, so the terminal running it needs Accessibility permission (Privacy & Security → Accessibility). It moves the mouse and quits and reopens System Settings while it runs.

```sh
nix run .#verify -- controls com.apple.settings.appearance         # labelled controls and their values
nix run .#verify -- discover com.apple.settings.appearance inventory/system-settings/appearance.json
                                                                    # add what the pane shows to the inventory
nix run .#verify -- observe com.apple.settings.appearance click "TintWindowBackgroundToggle"
                                                                    # which preference keys a control writes
nix run .#verify -- check --pane Appearance                        # round-trip every option with a `ui` spec
```

Panes are addressed by their sidebar identifier; `ax dump` lists them. Operate a control with `press` (buttons, radio buttons), `click` (SwiftUI switches ignore `press`), `pick` (pop-up menus) or `set` (sliders). Labels that appear more than once can be narrowed down: `AXRadioButton:Dark` matches only radio buttons, and `Dark + Icon & widget style` matches only an element that carries both labels.

`discover` is how panes whose `coverage` is `none` get their settings, and how the others get the ones Apple's metadata leaves out. Use `--open "Hot Corners…"` to reach sheets and sub-pages.

`check` needs a `ui` spec on the setting that says what System Settings should show for each value. Its format is described at the top of `tools/verify/verify.py`. `check` backs up the setting's preference keys, applies each value with the option's own generated command, reopens the pane and compares, then restores the backup. Settings that pass get `verified`.

Write the storage you record in `storage` from what `observe` reports. Don't take it from an existing option: an option that writes the wrong domain (for example `ByHost` when System Settings writes the global domain) still "works" in one direction, but it silently overrides whatever the user picks in the UI.

### A new macOS release

Run `nix run .#inventory -- extract` on the new release, then `sync` and `report`, and review the diff:

- New entries are settings that didn't exist before, or that Apple renamed. If one was renamed, move the `option` to the new entry with `link`.
- Entries whose `lastSeen` stayed on the old build weren't found on the new one. Check whether they were removed or moved.
- `verified` records the build the option was verified on, so after a release re-verify the options you touch.

If `extract` reports a skipped bundle, add it to `INTENT_BUNDLE_PANES` in `tools/inventory/inventory.py`. The other tables at the top of that file handle naming quirks.

### Merge duplicates

The same setting is often found by more than one source under different titles, e.g. "Accent color" from App Intents and "Color" from the UI. Fold one into the other:

```sh
nix run .#inventory -- merge inventory/system-settings/appearance.json#color inventory/system-settings/appearance.json#main-accent-color
```

### Skip something

Not everything in the inventory can be managed declaratively. Examples are privacy permissions, account settings, actions like "Set up Bluetooth keyboard", and search-term entries that duplicate an intent entry. Run `nix run .#inventory -- skip <file>#<setting-id> "<reason>"` so nobody else investigates them again.

## CI

`nix run .#inventory -- check` runs on every pull request. It fails when:
- an entry has an unknown field or kind,
- an `option` doesn't exist in `lib/options`,
- `COVERAGE.md` wasn't regenerated.
