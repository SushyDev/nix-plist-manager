# nix-plist-manager

[![Check](https://github.com/SushyDev/nix-plist-manager/actions/workflows/check.yml/badge.svg)](https://github.com/SushyDev/nix-plist-manager/actions/workflows/check.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Your Mac's System Settings, declared in Nix.** Set up a new Mac the way you like it on its first rebuild, and keep every Mac you use the same.

```nix
programs.nix-plist-manager = {
  enable = true;
  options.applications.systemSettings = {
    appearance.appearance = "Dark";
    appearance.accentColor = "Pink";
    displays.trueTone = false;
    displays.nightShift.schedule = "Sunset to Sunrise";
    desktopAndDock.dock.size = 36;
    desktopAndDock.dock.showSuggestedAndRecentAppsInDock = false;
    desktopAndDock.hotCorners.topRight.action = "Lock Screen";
    accessibility.pointerControl.trackpadOptions.dragging = "Three Finger Drag";
    keyboard.keyboardShortcuts.screenshots.copyPictureOfSelectedAreaToTheClipboard = "⌘⇧S";
    menuBar.clock.style = "Digital";
    menuBar.clock.displayTheTimeWithSeconds = true;
  };
};
```

## Why

- **552 settings**: 506 per user through home-manager, and 46 system-wide ones (firewall, sharing, power, login window) through nix-darwin.
- **Named after what you click.** `desktopAndDock.dock.automaticallyHideAndShowTheDock` is the switch labeled *Automatically hide and show the Dock*, and the values are the words in the menus: `"Sunset to Sunrise"`, `"Three Finger Drag"`.
- **Checked against the real thing.** 398 settings are round-tripped through System Settings: each value is applied, System Settings is asked what it shows, and the Mac is put back.
- **Applied the way macOS does it.** The Dock restarts, keyboard shortcuts take effect without logging out, and the firewall and sharing go through Apple's own tools.
- **Start from the Mac you have.** One command writes your current settings out as Nix, leaving out what's still at macOS's default.

## Compatibility

Built and verified on **macOS 27** (build 26A428). Earlier versions of macOS aren't tested: many settings are kept the same way there, but some moved or don't exist.

## Get started

Add the flake and its modules:

```nix
inputs.nix-plist-manager.url = "github:sushydev/nix-plist-manager";

# nix-darwin
modules = [ nix-plist-manager.darwinModules.default ];
# home-manager
home-manager.sharedModules = [ nix-plist-manager.homeManagerModules.default ];
```

Then write down the Mac you already have:

```sh
nix run github:sushydev/nix-plist-manager#current -- mac.nix --scope user
```

and import it with `options = import ./mac.nix;`. After changing something in System Settings, `--against mac.nix` prints just what's different.

The [documentation](https://sushydev.github.io/nix-plist-manager/) lists every setting with the values it takes, and covers [installing](https://sushydev.github.io/nix-plist-manager/guides/install/), [keyboard shortcuts](https://sushydev.github.io/nix-plist-manager/guides/keyboard-shortcuts/) and [snapshots](https://sushydev.github.io/nix-plist-manager/guides/snapshots/) of things you arrange rather than type, like the menu bar.

## What it doesn't do

Some things macOS keeps outside its preferences can't be declared: privacy permissions (camera, microphone, full disk access), Screen Time, and account settings. Each page of the documentation lists what isn't covered in its pane, and why.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). What's verified, still to do, and not covered is recorded in [coverage.json](coverage.json).

## License

[MIT](LICENSE)
