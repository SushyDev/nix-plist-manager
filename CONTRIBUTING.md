# Contributing

Every option lives in `lib/options/`, one file per System Settings pane or app. The option list, the activation commands and the website are all generated from them.

[`coverage.json`](coverage.json) records what the options alone can't say:

- `verified`: per macOS build, the options that `nix run .#verify -- check` confirmed in System Settings. `check` keeps it up to date.
- `todo`: per pane, settings that should get an option but don't have one yet, grouped by what's in the way.
- `notCovered`: per pane, settings that can't or shouldn't be declared (privacy permissions, account state, actions, per-device hardware), grouped by the reason. The website lists them on each pane's page so nobody investigates them again.

`nix flake check` fails when `verified` names an option that doesn't exist.

## Workflows

### Implement a setting

1. Pick one from `todo` in `coverage.json`, or a control System Settings shows that nothing accounts for yet: `nix run .#verify -- gaps` lists those for every pane (`--pane Keyboard` for one), and after a macOS update it's how new settings turn up.
2. Find where it's stored. Run `nix run .#watch` (or `nix run .#watch -- com.apple.dock` for one domain), flip the setting in System Settings and note the domain, key and value it prints. `nix run .#verify -- observe <pane> click "<control>"` does the same by operating the control for you.
3. Register it as a `setting` under `lib/options/…` (see [Writing a setting](#writing-a-setting)) and remove it from `todo`.
4. Give it a `verify` spec and run `nix run .#verify -- check --option <option.path>` (see below), which adds it to `verified` when System Settings shows every value the option sets.
5. Commit the option and `coverage.json` together.

New files have to be `git add`ed before `nix` can see them.

### Writing a setting

A setting is data: where it is in System Settings, where the value is stored, how values are encoded, and how it behaves. The option, the activation commands and the docs are all derived from it, in `lib/settings/`.

```nix
{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting global user enum number bool inverted restarts notifies allowedWhen;
in
{
	allowWallpaperTintingInWindows = setting {
		ui = [ "System Settings" "Appearance" "Windows" "Tint window background with wallpaper color" ];
		storage = global "AppleReduceDesktopTinting";
		value = inverted bool;   # the key says "reduce", the switch says "tint"
		verify = {
			pane = "com.apple.settings.appearance";
			operate = [ "click" "TintWindowBackgroundToggle" ];
			expect = {
				true = { TintWindowBackgroundToggle = 1; };
				false = { TintWindowBackgroundToggle = 0; };
			};
		};
	};
}
```

| Part | What's there | File |
| --- | --- | --- |
| `ui` | The full path to the control in the UI's own words, starting at the app ("System Settings", "Finder", "Dock", "Menu bar"): pane, sub-page, the button that opens a sheet ("Advanced…", or "Speak selection (i)" for an info button), then the control's label. The docs show it as the way to the setting; `nix flake check` fails when it doesn't start at an app. | `setting.nix` |
| `storage` | `user "<domain>" "<key>"`, `global "<key>"` (NSGlobalDomain), `system "<domain>" "<key>"` (nix-darwin, as root), wrapped in `byHost` for the current-host copy or `stored "float"` to force the plist type. Several keys: `{ color = global "…"; variant = global "…"; }`. | `storage.nix` |
| `value` | `bool`, `inverted bool`, `text`, `strings`, `number { min; max; stored ? ; }`, `enum { "<label as shown>" = <stored value>; }` (`absent` deletes the key, `{ <key name> = …; }` writes several), `storedAs { true = 1; false = 0; } bool` (other stored values for a switch), `inDict "<entry>" <codec>` (one entry of a dictionary, the rest left alone), `dictSwitches`, `members` and `flags { <name> = <bit>; }` (named switches kept in a dictionary, an array or a bitmask; switches left out are kept), `hotKey <id>` (a keyboard shortcut, written as `"⌘⇧S"`; see `shortcuts.nix`). | `codecs.nix` |
| `behaviors` | `restarts "Dock"` and `notifies "…"` run once after all writes, and `activatesShortcuts` once at the very end; `appliesThrough (value: "<command>")` for state a system service owns, with the commands for those in `live.nix`. Every setting also clears a stale ByHost copy of its keys. | `behaviors.nix` |
| `reads` | For state a service keeps rather than a preference (pmset, the firewall, sharing): `{ command; values ? null; }`, a command that prints the value, and what it prints for each value when that isn't the value itself. `nix run .#current` runs it. | `setting.nix` |
| `relations` | `onlyWhen`, `allowedWhen`, `conflictsWith` and `implies`, against other settings by option path. They fail evaluation when both settings are managed and disagree, and warn when the other one isn't managed (silenced with `ignoreWarnings`). | `relations.nix` |
| `family` | Settings with the same shape, generated from a table (e.g. the four hot corners). | `setting.nix` |
| `snapshot` | For state that's arranged rather than typed, like the menu bar layout: `storage` lists whole domains (`domain "…"`) and single keys, `nix run .#capture -- <option> <dir>` saves them as plists, and the option takes that directory. Each entry is replaced by what was captured. | `codecs.nix` |

Settings people change often in daily use (brightness, volume) and per-device hardware state (resolution, a specific monitor's preset) don't get options: add them to `notCovered` with the reason.

Every setting accepts `null` (not managed) and `"unset"` (delete the keys, back to the macOS default) on top of what its value type allows. `nix flake check` runs the library's tests in `lib/settings/tests.nix`.

Renamed or removed options go in `modules/deprecations.nix`, not in the option files.

### Try settings without rebuilding your system

`nix run .#apply` applies settings straight from this checkout, with the same type checks and relations as a system configuration:

```sh
nix run .#apply -- set applications.systemSettings.appearance.accentColor '"Graphite"'
nix run .#apply -- set applications.systemSettings.desktopAndDock.dock.size 48 --dry-run
nix run .#apply -- config ./my-settings.nix      # { applications.systemSettings.… = …; }
```

The value is a Nix expression, so strings need their quotes. `--dry-run` prints the script instead of running it. System settings (nix-darwin's) run through `sudo`.

`nix eval --raw ./tests/modules#home` (or `#darwin`) evaluates the modules inside real home-manager and nix-darwin configurations and prints the activation script they produce.

### Verify against the real UI

`tools/verify.py` drives System Settings through the Accessibility API, so the terminal running it needs Accessibility permission (Privacy & Security → Accessibility). It moves the mouse and quits and reopens System Settings while it runs.

```sh
nix run .#verify -- discover com.apple.settings.appearance        # the settings the pane shows
nix run .#verify -- gaps --pane Appearance                         # what no option or coverage.json entry accounts for
nix run .#verify -- observe com.apple.settings.appearance click "TintWindowBackgroundToggle"
                                                                    # which preference keys a control writes
nix run .#verify -- check --pane Appearance                        # round-trip every setting with a `verify` spec
nix run .#verify -- check --pane Keyboard --batch --skip 'Speak'    # a page's settings together; leave some out
```

Panes are addressed by their sidebar identifier; `gaps` walks all of them, and `ax dump` lists them. Operate a control with `press` (buttons, radio buttons), `click` (SwiftUI switches ignore `press`), `pick` (pop-up menus) or `set` (sliders). Labels that appear more than once can be narrowed down: `AXRadioButton:Dark` matches only radio buttons, `Dark + Icon & widget style` matches only an element that carries both labels, and `…#2` picks the second match (e.g. the second of a list's disclosure triangles). An unlabeled checkbox in a list row goes by the row's text. In a spec's `open` steps, `click:<label>` clicks instead of pressing, for list rows that ignore `press` (Keyboard Shortcuts…'s categories).

`check --batch` applies the same case of every setting that has the same `open` steps, opens that page once and reads all of their controls, which is many times faster. Give the settings of one page values that can't be mistaken for each other (the keyboard shortcuts each use their own test keys); a setting that fails in a batch can be checked on its own with `--option`. `--skip <regex>` leaves settings out by UI path, e.g. ones that would speak or play sound.

`discover` lists the switches, sliders, pop-ups and sheets a pane shows. Use `--open "Hot Corners…"` to reach sheets and sub-pages; `ax items <pop-up>` lists a pop-up's choices.

`check` needs a `verify` spec on the setting that says what System Settings should show for each value. Its format is described at the top of `tools/verify.py`. `check` backs up the setting's preference keys, applies each value with the option's own generated command, reopens the pane and compares, then restores the backup. Options that pass are added to `verified` under the current build; options that fail are removed.

Write the setting's `storage` from what `observe` reports. Don't take it from an existing option: an option that writes the wrong domain (for example `ByHost` when System Settings writes the global domain) still "works" in one direction, but it silently overrides whatever the user picks in the UI.

### A new macOS release

Run `nix run .#verify -- check --batch` on the new release. The options that still pass move to the new build in `verified`; the ones that fail are dropped and need a look. Walk the panes with `discover` for settings that are new.
