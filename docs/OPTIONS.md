# Nix Plist Manager Options Reference

This document describes all available configuration options for the Nix Plist Manager. These options allow you to configure macOS system settings and application preferences through Nix.

## Table of Contents

- [System Settings](#system-settings)
  - [Appearance](#appearance)
  - [Control Center](#control-center)
  - [Desktop & Dock](#desktop--dock)
  - [Focus](#focus)
  - [General](#general)
  - [Keyboard](#keyboard)
  - [Notifications](#notifications)
  - [Sound](#sound)
  - [Spotlight](#spotlight)
  - [Trackpad](#trackpad)
- [Applications](#applications)
  - [Finder](#finder)

## System Settings

### Appearance

#### `systemSettings.appearance`

**Type:** `nullOr (enum ["Light", "Dark", "Auto"])`

**Default:** `null`

**Description:** Controls the appearance theme for macOS.

**Example:**
```nix
systemSettings.appearance = "Dark";
```

#### `systemSettings.accentColor`

**Type:** `nullOr (enum ["Graphite", "Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Pink", "Multicolor"])`

**Default:** `null`

**Description:** Sets the accent color used throughout the system interface.

**Example:**
```nix
systemSettings.accentColor = "Blue";
```

#### `systemSettings.sidebarIconSize`

**Type:** `nullOr (enum ["Small", "Medium", "Large"])`

**Default:** `null`

**Description:** Controls the size of icons in Finder sidebars and other system interfaces.

**Example:**
```nix
systemSettings.sidebarIconSize = "Medium";
```

#### `systemSettings.allowWallpaperTintingInWindows`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to allow wallpaper tinting effects in application windows.

**Example:**
```nix
systemSettings.allowWallpaperTintingInWindows = true;
```

#### `systemSettings.showScrollBars`

**Type:** `nullOr (enum ["Automatically based on mouse or trackpad", "When scrolling", "Always"])`

**Default:** `null`

**Description:** Controls when scroll bars are displayed in windows.

**Example:**
```nix
systemSettings.showScrollBars = "Always";
```

#### `systemSettings.clickInTheScrollBarTo`

**Type:** `nullOr (enum ["Jump to the next page", "Jump to the spot that's clicked"])`

**Default:** `null`

**Description:** Controls the behavior when clicking in the scroll bar track.

**Example:**
```nix
systemSettings.clickInTheScrollBarTo = "Jump to the spot that's clicked";
```

### Control Center

#### `systemSettings.controlCenter.wifi`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to show Wi-Fi controls in the menu bar.

**Example:**
```nix
systemSettings.controlCenter.wifi = true;
```

#### `systemSettings.controlCenter.bluetooth`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to show Bluetooth controls in the menu bar.

**Example:**
```nix
systemSettings.controlCenter.bluetooth = true;
```

#### `systemSettings.controlCenter.airdrop`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to show AirDrop controls in the menu bar.

**Example:**
```nix
systemSettings.controlCenter.airdrop = true;
```

#### `systemSettings.controlCenter.stageManager`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to show Stage Manager controls in the menu bar.

**Example:**
```nix
systemSettings.controlCenter.stageManager = true;
```

#### `systemSettings.controlCenter.focusModes`

**Type:** `nullOr (enum ["always", "active", "never"])`

**Default:** `null`

**Description:** Controls the visibility of Focus modes in the Control Center.

**Example:**
```nix
systemSettings.controlCenter.focusModes = "always";
```

#### `systemSettings.controlCenter.screenMirroring`

**Type:** `nullOr (enum ["always", "active", "never"])`

**Default:** `null`

**Description:** Controls the visibility of screen mirroring controls in the Control Center.

**Example:**
```nix
systemSettings.controlCenter.screenMirroring = "active";
```

#### `systemSettings.controlCenter.display`

**Type:** `nullOr (enum ["always", "active", "never"])`

**Default:** `null`

**Description:** Controls the visibility of display controls in the Control Center.

**Example:**
```nix
systemSettings.controlCenter.display = "always";
```

#### `systemSettings.controlCenter.sound`

**Type:** `nullOr (enum ["always", "active", "never"])`

**Default:** `null`

**Description:** Controls the visibility of sound controls in the Control Center.

**Example:**
```nix
systemSettings.controlCenter.sound = "always";
```

#### `systemSettings.controlCenter.nowPlaying`

**Type:** `nullOr (enum ["always", "active", "never"])`

**Default:** `null`

**Description:** Controls the visibility of Now Playing controls in the Control Center.

**Example:**
```nix
systemSettings.controlCenter.nowPlaying = "active";
```

#### `systemSettings.controlCenter.accessibilityShortcuts`

**Type:** `nullOr (submodule { showInMenuBar = nullOr bool; showInControlCenter = nullOr bool; })`

**Default:** `null`

**Description:** Controls the visibility of accessibility shortcuts in the menu bar and Control Center.

**Example:**
```nix
systemSettings.controlCenter.accessibilityShortcuts = {
  showInMenuBar = true;
  showInControlCenter = false;
};
```

#### `systemSettings.controlCenter.musicRecognition`

**Type:** `nullOr (submodule { showInMenuBar = nullOr bool; showInControlCenter = nullOr bool; })`

**Default:** `null`

**Description:** Controls the visibility of music recognition controls in the menu bar and Control Center.

**Example:**
```nix
systemSettings.controlCenter.musicRecognition = {
  showInMenuBar = true;
  showInControlCenter = true;
};
```

#### `systemSettings.controlCenter.hearing`

**Type:** `nullOr (submodule { showInMenuBar = nullOr bool; showInControlCenter = nullOr bool; })`

**Default:** `null`

**Description:** Controls the visibility of hearing controls in the menu bar and Control Center.

**Example:**
```nix
systemSettings.controlCenter.hearing = {
  showInMenuBar = false;
  showInControlCenter = true;
};
```

#### `systemSettings.controlCenter.fastUserSwitching`

**Type:** `nullOr (submodule { showInMenuBar = nullOr bool; showInControlCenter = nullOr bool; })`

**Default:** `null`

**Description:** Controls the visibility of fast user switching controls in the menu bar and Control Center.

**Example:**
```nix
systemSettings.controlCenter.fastUserSwitching = {
  showInMenuBar = true;
  showInControlCenter = false;
};
```

#### `systemSettings.controlCenter.keyboardBrightness`

**Type:** `nullOr (submodule { showInMenuBar = nullOr bool; showInControlCenter = nullOr bool; })`

**Default:** `null`

**Description:** Controls the visibility of keyboard brightness controls in the menu bar and Control Center.

**Example:**
```nix
systemSettings.controlCenter.keyboardBrightness = {
  showInMenuBar = false;
  showInControlCenter = true;
};
```

#### `systemSettings.controlCenter.battery`

**Type:** `nullOr (submodule { showInMenuBar = nullOr bool; showInControlCenter = nullOr bool; })`

**Default:** `null`

**Description:** Controls the visibility of battery information in the menu bar and Control Center.

**Example:**
```nix
systemSettings.controlCenter.battery = {
  showInMenuBar = true;
  showInControlCenter = true;
};
```

#### `systemSettings.controlCenter.batteryShowPercentage`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to show battery percentage in the battery indicator.

**Example:**
```nix
systemSettings.controlCenter.batteryShowPercentage = true;
```

#### `systemSettings.controlCenter.menuBarOnly.spotlight`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to show Spotlight in the menu bar only (not in Control Center).

**Example:**
```nix
systemSettings.controlCenter.menuBarOnly.spotlight = false;
```

#### `systemSettings.controlCenter.menuBarOnly.siri`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to show Siri in the menu bar only (not in Control Center).

**Example:**
```nix
systemSettings.controlCenter.menuBarOnly.siri = true;
```

#### `systemSettings.controlCenter.automaticallyHideAndShowTheMenuBar`

**Type:** `nullOr (enum ["Always", "On Desktop Only", "In Full Screen Only", "Never"])`

**Default:** `null`

**Description:** Controls when the menu bar automatically hides and shows.

**Example:**
```nix
systemSettings.controlCenter.automaticallyHideAndShowTheMenuBar = "Always";
```

### Desktop & Dock

#### Dock Options

##### `systemSettings.desktopAndDock.dock.size`

**Type:** `nullOr (ints.between 16 128)`

**Default:** `null`

**Description:** Sets the size of the Dock icons.

**Example:**
```nix
systemSettings.desktopAndDock.dock.size = 64;
```

##### `systemSettings.desktopAndDock.dock.magnification`

**Type:** `nullOr (submodule { enabled = nullOr bool; size = nullOr (ints.between 30 128); })`

**Default:** `null`

**Description:** Controls Dock magnification settings.

**Example:**
```nix
systemSettings.desktopAndDock.dock.magnification = {
  enabled = true;
  size = 64;
};
```

##### `systemSettings.desktopAndDock.dock.positionOnScreen`

**Type:** `nullOr (enum ["left", "bottom", "right"])`

**Default:** `null`

**Description:** Sets the position of the Dock on screen.

**Example:**
```nix
systemSettings.desktopAndDock.dock.positionOnScreen = "bottom";
```

##### `systemSettings.desktopAndDock.dock.minimizeWindowsUsing`

**Type:** `nullOr (enum ["genie", "scale"])`

**Default:** `null`

**Description:** Sets the animation effect used when minimizing windows.

**Example:**
```nix
systemSettings.desktopAndDock.dock.minimizeWindowsUsing = "genie";
```

##### `systemSettings.desktopAndDock.dock.doubleClickAWindowsTitleBarTo`

**Type:** `nullOr (enum ["fill", "zoom", "minimize", "doNothing"])`

**Default:** `null`

**Description:** Sets the action performed when double-clicking a window's title bar.

**Example:**
```nix
systemSettings.desktopAndDock.dock.doubleClickAWindowsTitleBarTo = "zoom";
```

##### `systemSettings.desktopAndDock.dock.minimizeWindowsIntoApplicationIcon`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether minimized windows should be represented by their application icon in the Dock.

**Example:**
```nix
systemSettings.desktopAndDock.dock.minimizeWindowsIntoApplicationIcon = true;
```

##### `systemSettings.desktopAndDock.dock.automaticallyHideAndShowTheDock`

**Type:** `nullOr (submodule { enabled = nullOr bool; delay = nullOr float; duration = nullOr float; })`

**Default:** `null`

**Description:** Controls automatic hiding and showing of the Dock.

**Example:**
```nix
systemSettings.desktopAndDock.dock.automaticallyHideAndShowTheDock = {
  enabled = true;
  delay = 0.5;
  duration = 0.3;
};
```

##### `systemSettings.desktopAndDock.dock.animateOpeningApplications`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to animate opening applications from the Dock.

**Example:**
```nix
systemSettings.desktopAndDock.dock.animateOpeningApplications = true;
```

##### `systemSettings.desktopAndDock.dock.showIndicatorsForOpenApplications`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to show indicators for open applications in the Dock.

**Example:**
```nix
systemSettings.desktopAndDock.dock.showIndicatorsForOpenApplications = true;
```

##### `systemSettings.desktopAndDock.dock.showSuggestedAndRecentAppsInDock`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to show suggested and recent apps in the Dock.

**Example:**
```nix
systemSettings.desktopAndDock.dock.showSuggestedAndRecentAppsInDock = false;
```

##### `systemSettings.desktopAndDock.dock.persistentApps`

**Type:** `nullOr (listOf taggedType)`

**Default:** `null`

**Description:** List of applications to keep persistently in the Dock.

**Example:**
```nix
systemSettings.desktopAndDock.dock.persistentApps = [
  { app = "/Applications/Safari.app"; }
  { app = "/Applications/VSCode.app"; }
];
```

##### `systemSettings.desktopAndDock.dock.persistentOthers`

**Type:** `nullOr (listOf (either path str))`

**Default:** `null`

**Description:** List of folders and files to keep persistently in the Dock.

**Example:**
```nix
systemSettings.desktopAndDock.dock.persistentOthers = [
  "~/Documents"
  "~/Downloads"
];
```

#### Desktop & Stage Manager

##### `systemSettings.desktopAndDock.desktopAndStageManager.showItems`

**Type:** `nullOr (submodule { onDesktop = nullOr bool; inStageManager = nullOr bool; })`

**Default:** `null`

**Description:** Controls whether to show items on the desktop and in Stage Manager.

**Example:**
```nix
systemSettings.desktopAndDock.desktopAndStageManager.showItems = {
  onDesktop = true;
  inStageManager = false;
};
```

##### `systemSettings.desktopAndDock.desktopAndStageManager.clickWallpaperToRevealDesktop`

**Type:** `nullOr (enum ["always", "onlyInStageManager"])`

**Default:** `null`

**Description:** Controls when clicking the wallpaper reveals the desktop.

**Example:**
```nix
systemSettings.desktopAndDock.desktopAndStageManager.clickWallpaperToRevealDesktop = "always";
```

##### `systemSettings.desktopAndDock.desktopAndStageManager.stageManager`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to enable Stage Manager.

**Example:**
```nix
systemSettings.desktopAndDock.desktopAndStageManager.stageManager = true;
```

##### `systemSettings.desktopAndDock.desktopAndStageManager.showRecentAppsInStageManager`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to show recent apps in Stage Manager.

**Example:**
```nix
systemSettings.desktopAndDock.desktopAndStageManager.showRecentAppsInStageManager = true;
```

##### `systemSettings.desktopAndDock.desktopAndStageManager.showWindowsFromAnApplication`

**Type:** `nullOr (enum ["allAtOnce", "oneAtATime"])`

**Default:** `null`

**Description:** Controls how windows from an application are shown.

**Example:**
```nix
systemSettings.desktopAndDock.desktopAndStageManager.showWindowsFromAnApplication = "allAtOnce";
```

#### Widgets

##### `systemSettings.desktopAndDock.widgets.showWidgets`

**Type:** `nullOr (submodule { onDesktop = nullOr bool; inStageManager = nullOr bool; })`

**Default:** `null`

**Description:** Controls whether to show widgets on the desktop and in Stage Manager.

**Example:**
```nix
systemSettings.desktopAndDock.widgets.showWidgets = {
  onDesktop = true;
  inStageManager = false;
};
```

##### `systemSettings.desktopAndDock.widgets.widgetStyle`

**Type:** `nullOr (enum ["automatic", "monochrome", "full-color"])`

**Default:** `null`

**Description:** Sets the style for widgets.

**Example:**
```nix
systemSettings.desktopAndDock.widgets.widgetStyle = "automatic";
```

##### `systemSettings.desktopAndDock.widgets.useIphoneWidgets`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to use iPhone widgets.

**Example:**
```nix
systemSettings.desktopAndDock.widgets.useIphoneWidgets = true;
```

#### Windows

##### `systemSettings.desktopAndDock.windows.preferTabsWhenOpeningDocuments`

**Type:** `nullOr (enum ["never", "always", "inFullScreen"])`

**Default:** `null`

**Description:** Controls when to prefer tabs when opening documents.

**Example:**
```nix
systemSettings.desktopAndDock.windows.preferTabsWhenOpeningDocuments = "always";
```

##### `systemSettings.desktopAndDock.windows.askToKeepChangesWhenClosingDocuments`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to ask to keep changes when closing documents.

**Example:**
```nix
systemSettings.desktopAndDock.windows.askToKeepChangesWhenClosingDocuments = true;
```

##### `systemSettings.desktopAndDock.windows.closeWindowsWhenQuittingAnApplication`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to close windows when quitting an application.

**Example:**
```nix
systemSettings.desktopAndDock.windows.closeWindowsWhenQuittingAnApplication = false;
```

##### `systemSettings.desktopAndDock.windows.dragWindowsToScreenEdgesToTile`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to tile windows when dragging to screen edges.

**Example:**
```nix
systemSettings.desktopAndDock.windows.dragWindowsToScreenEdgesToTile = true;
```

##### `systemSettings.desktopAndDock.windows.dragWindowsToMenuBarToFillScreen`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to fill screen when dragging windows to menu bar.

**Example:**
```nix
systemSettings.desktopAndDock.windows.dragWindowsToMenuBarToFillScreen = true;
```

##### `systemSettings.desktopAndDock.windows.holdOptionKeyWhileDraggingWindowsToTile`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to require holding Option key while dragging windows to tile.

**Example:**
```nix
systemSettings.desktopAndDock.windows.holdOptionKeyWhileDraggingWindowsToTile = false;
```

##### `systemSettings.desktopAndDock.windows.tiledWindowsHaveMargin`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether tiled windows have margins.

**Example:**
```nix
systemSettings.desktopAndDock.windows.tiledWindowsHaveMargin = true;
```

#### Mission Control

##### `systemSettings.desktopAndDock.missionControl.automaticallyRearrangeSpacesBasedOnMostRecentUse`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to automatically rearrange Spaces based on most recent use.

**Example:**
```nix
systemSettings.desktopAndDock.missionControl.automaticallyRearrangeSpacesBasedOnMostRecentUse = true;
```

##### `systemSettings.desktopAndDock.missionControl.whenSwitchingToAnApplicationSwitchToAspaceWithOpenWindowsForTheApplication`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to switch to a Space with open windows for the application when switching to an application.

**Example:**
```nix
systemSettings.desktopAndDock.missionControl.whenSwitchingToAnApplicationSwitchToAspaceWithOpenWindowsForTheApplication = true;
```

##### `systemSettings.desktopAndDock.missionControl.groupWindowsByApplication`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to group windows by application in Mission Control.

**Example:**
```nix
systemSettings.desktopAndDock.missionControl.groupWindowsByApplication = true;
```

##### `systemSettings.desktopAndDock.missionControl.displaysHaveSeparateSpaces`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether displays have separate Spaces.

**Example:**
```nix
systemSettings.desktopAndDock.missionControl.displaysHaveSeparateSpaces = true;
```

##### `systemSettings.desktopAndDock.missionControl.dragWindowsToTopOfScreenToEnterMissionControl`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether dragging windows to the top of screen enters Mission Control.

**Example:**
```nix
systemSettings.desktopAndDock.missionControl.dragWindowsToTopOfScreenToEnterMissionControl = true;
```

#### Hot Corners

##### `systemSettings.desktopAndDock.hotCorners.topLeft`

**Type:** `nullOr (enum ["disabled", "missionControl", "applicationWindows", "desktop", "startScreenSaver", "disableScreenSaver", "dashboard", "putDisplayToSleep", "launchpad", "notificationCenter", "lockScreen", "quickNote"])`

**Default:** `null`

**Description:** Sets the action for the top-left hot corner.

**Example:**
```nix
systemSettings.desktopAndDock.hotCorners.topLeft = "missionControl";
```

##### `systemSettings.desktopAndDock.hotCorners.topRight`

**Type:** `nullOr (enum ["disabled", "missionControl", "applicationWindows", "desktop", "startScreenSaver", "disableScreenSaver", "dashboard", "putDisplayToSleep", "launchpad", "notificationCenter", "lockScreen", "quickNote"])`

**Default:** `null`

**Description:** Sets the action for the top-right hot corner.

**Example:**
```nix
systemSettings.desktopAndDock.hotCorners.topRight = "desktop";
```

##### `systemSettings.desktopAndDock.hotCorners.bottomLeft`

**Type:** `nullOr (enum ["disabled", "missionControl", "applicationWindows", "desktop", "startScreenSaver", "disableScreenSaver", "dashboard", "putDisplayToSleep", "launchpad", "notificationCenter", "lockScreen", "quickNote"])`

**Default:** `null`

**Description:** Sets the action for the bottom-left hot corner.

**Example:**
```nix
systemSettings.desktopAndDock.hotCorners.bottomLeft = "launchpad";
```

##### `systemSettings.desktopAndDock.hotCorners.bottomRight`

**Type:** `nullOr (enum ["disabled", "missionControl", "applicationWindows", "desktop", "startScreenSaver", "disableScreenSaver", "dashboard", "putDisplayToSleep", "launchpad", "notificationCenter", "lockScreen", "quickNote"])`

**Default:** `null`

**Description:** Sets the action for the bottom-right hot corner.

**Example:**
```nix
systemSettings.desktopAndDock.hotCorners.bottomRight = "notificationCenter";
```

#### Desktop & Stage Manager
- **desktopAndStageManager.showItems**
  - Type: `nullOr (submodule { onDesktop = nullOr bool; inStageManager = nullOr bool; })`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.desktopAndStageManager.showItems = { onDesktop = true; inStageManager = false; };`

- **desktopAndStageManager.clickWallpaperToRevealDesktop**
  - Type: `nullOr (enum ["always", "onlyInStageManager"])`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.desktopAndStageManager.clickWallpaperToRevealDesktop = "always";`

- **desktopAndStageManager.stageManager**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.desktopAndStageManager.stageManager = true;`

- **desktopAndStageManager.showRecentAppsInStageManager**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.desktopAndStageManager.showRecentAppsInStageManager = true;`

- **desktopAndStageManager.showWindowsFromAnApplication**
  - Type: `nullOr (enum ["allAtOnce", "oneAtATime"])`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.desktopAndStageManager.showWindowsFromAnApplication = "allAtOnce";`

#### Widgets
- **widgets.showWidgets**
  - Type: `nullOr (submodule { onDesktop = nullOr bool; inStageManager = nullOr bool; })`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.widgets.showWidgets = { onDesktop = true; inStageManager = false; };`

- **widgets.widgetStyle**
  - Type: `nullOr (enum ["automatic", "monochrome", "full-color"])`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.widgets.widgetStyle = "automatic";`

- **widgets.useIphoneWidgets**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.widgets.useIphoneWidgets = true;`

#### Windows
- **windows.preferTabsWhenOpeningDocuments**
  - Type: `nullOr (enum ["never", "always", "inFullScreen"])`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.windows.preferTabsWhenOpeningDocuments = "always";`

- **windows.askToKeepChangesWhenClosingDocuments**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.windows.askToKeepChangesWhenClosingDocuments = true;`

- **windows.closeWindowsWhenQuittingAnApplication**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.windows.closeWindowsWhenQuittingAnApplication = false;`

- **windows.dragWindowsToScreenEdgesToTile**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.windows.dragWindowsToScreenEdgesToTile = true;`

- **windows.dragWindowsToMenuBarToFillScreen**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.windows.dragWindowsToMenuBarToFillScreen = true;`

- **windows.holdOptionKeyWhileDraggingWindowsToTile**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.windows.holdOptionKeyWhileDraggingWindowsToTile = false;`

- **windows.tiledWindowsHaveMargin**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.windows.tiledWindowsHaveMargin = true;`

#### Mission Control
- **missionControl.automaticallyRearrangeSpacesBasedOnMostRecentUse**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.missionControl.automaticallyRearrangeSpacesBasedOnMostRecentUse = true;`

- **missionControl.whenSwitchingToAnApplicationSwitchToAspaceWithOpenWindowsForTheApplication**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.missionControl.whenSwitchingToAnApplicationSwitchToAspaceWithOpenWindowsForTheApplication = true;`

- **missionControl.groupWindowsByApplication**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.missionControl.groupWindowsByApplication = true;`

- **missionControl.displaysHaveSeparateSpaces**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.missionControl.displaysHaveSeparateSpaces = true;`

- **missionControl.dragWindowsToTopOfScreenToEnterMissionControl**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.missionControl.dragWindowsToTopOfScreenToEnterMissionControl = true;`

#### Hot Corners
- **hotCorners.topLeft**
  - Type: `nullOr (enum ["disabled", "missionControl", "applicationWindows", "desktop", "startScreenSaver", "disableScreenSaver", "dashboard", "putDisplayToSleep", "launchpad", "notificationCenter", "lockScreen", "quickNote"])`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.hotCorners.topLeft = "missionControl";`

- **hotCorners.topRight**
  - Type: `nullOr (enum ["disabled", "missionControl", "applicationWindows", "desktop", "startScreenSaver", "disableScreenSaver", "dashboard", "putDisplayToSleep", "launchpad", "notificationCenter", "lockScreen", "quickNote"])`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.hotCorners.topRight = "desktop";`

- **hotCorners.bottomLeft**
  - Type: `nullOr (enum ["disabled", "missionControl", "applicationWindows", "desktop", "startScreenSaver", "disableScreenSaver", "dashboard", "putDisplayToSleep", "launchpad", "notificationCenter", "lockScreen", "quickNote"])`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.hotCorners.bottomLeft = "launchpad";`

- **hotCorners.bottomRight**
  - Type: `nullOr (enum ["disabled", "missionControl", "applicationWindows", "desktop", "startScreenSaver", "disableScreenSaver", "dashboard", "putDisplayToSleep", "launchpad", "notificationCenter", "lockScreen", "quickNote"])`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.hotCorners.bottomRight = "notificationCenter";`

### Focus

#### `systemSettings.focus.shareAcrossDevices`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to share Focus settings across devices.

**Example:**
```nix
systemSettings.focus.shareAcrossDevices = false;
```

### General

#### Software Update

##### `systemSettings.general.softwareUpdate.automaticallyDownloadNewUpdatesWhenAvailable`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to automatically download new updates when available.

**Example:**
```nix
systemSettings.general.softwareUpdate.automaticallyDownloadNewUpdatesWhenAvailable = true;
```

##### `systemSettings.general.softwareUpdate.automaticallyInstallMacOSUpdates`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to automatically install macOS updates.

**Example:**
```nix
systemSettings.general.softwareUpdate.automaticallyInstallMacOSUpdates = false;
```

##### `systemSettings.general.softwareUpdate.automaticallyInstallApplicationUpdatesFromTheAppStore`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to automatically install application updates from the App Store.

**Example:**
```nix
systemSettings.general.softwareUpdate.automaticallyInstallApplicationUpdatesFromTheAppStore = true;
```

##### `systemSettings.general.softwareUpdate.automaticallyInstallSecurityResponseAndSystemFiles`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to automatically install security responses and system files.

**Example:**
```nix
systemSettings.general.softwareUpdate.automaticallyInstallSecurityResponseAndSystemFiles = true;
```

#### Date & Time

##### `systemSettings.general.dateAndTime.setTimeAndDateAutomatically`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to set time and date automatically.

**Example:**
```nix
systemSettings.general.dateAndTime.setTimeAndDateAutomatically = true;
```

##### `systemSettings.general.dateAndTime."24HourTime"`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to use 24-hour time format.

**Example:**
```nix
systemSettings.general.dateAndTime."24HourTime" = true;
```

##### `systemSettings.general.dateAndTime.show24HourTimeOnLockScreen`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to show 24-hour time on the lock screen.

**Example:**
```nix
systemSettings.general.dateAndTime.show24HourTimeOnLockScreen = true;
```

##### `systemSettings.general.dateAndTime.setTimeZoneAutomaticallyUsingCurrentLocation`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to set time zone automatically using current location.

**Example:**
```nix
systemSettings.general.dateAndTime.setTimeZoneAutomaticallyUsingCurrentLocation = true;
```

### Keyboard

#### `systemSettings.keyboard.keyRepeatRate`

**Type:** `nullOr (ints.between 1 7)`

**Default:** `null`

**Description:** Sets the key repeat rate (higher numbers = faster repeat).

**Example:**
```nix
systemSettings.keyboard.keyRepeatRate = 3;
```

#### `systemSettings.keyboard.keyRepeatDelay`

**Type:** `nullOr (ints.between 1 6)`

**Default:** `null`

**Description:** Sets the delay before key repeat starts (higher numbers = longer delay).

**Example:**
```nix
systemSettings.keyboard.keyRepeatDelay = 2;
```

#### `systemSettings.keyboard.adjustKeyboardBrightnessInLowLight`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to automatically adjust keyboard brightness in low light.

**Example:**
```nix
systemSettings.keyboard.adjustKeyboardBrightnessInLowLight = true;
```

#### `systemSettings.keyboard.keyboardBrightness`

**Type:** `nullOr (floatBetween 0.0 1.0)`

**Default:** `null`

**Description:** Sets the keyboard brightness level.

**Example:**
```nix
systemSettings.keyboard.keyboardBrightness = 0.5;
```

#### `systemSettings.keyboard.turnKeyboardBacklightOffAfterInactivity`

**Type:** `nullOr (enum ["After 5 Seconds", "After 10 Seconds", "After 30 Seconds", "After 1 Minute", "After 5 Minutes", "Never"])`

**Default:** `null`

**Description:** Sets when to turn off keyboard backlight after inactivity.

**Example:**
```nix
systemSettings.keyboard.turnKeyboardBacklightOffAfterInactivity = "After 1 Minute";
```

#### `systemSettings.keyboard.pressGlobeKeyTo`

**Type:** `nullOr (enum ["Change Input Source", "Show Emoji & Symbols", "Start Dictation (Press Globe Key Twice)", "Do Nothing"])`

**Default:** `null`

**Description:** Sets the action performed when pressing the Globe key.

**Example:**
```nix
systemSettings.keyboard.pressGlobeKeyTo = "Show Emoji & Symbols";
```

#### `systemSettings.keyboard.keyboardNavigation`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to enable keyboard navigation for interface controls.

**Example:**
```nix
systemSettings.keyboard.keyboardNavigation = true;
```

#### Keyboard Shortcuts

##### `systemSettings.keyboard.keyboardShortcuts.functionKeys.useF1F2EtcAsStandardFunctionKeys`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to use F1, F2, etc. keys as standard function keys.

**Example:**
```nix
systemSettings.keyboard.keyboardShortcuts.functionKeys.useF1F2EtcAsStandardFunctionKeys = true;
```

#### Dictation

##### `systemSettings.keyboard.dictation.enabled`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to enable dictation.

**Example:**
```nix
systemSettings.keyboard.dictation.enabled = true;
```

### Notifications

#### Notification Center

##### `systemSettings.notifications.notificationCenter.showPreviews`

**Type:** `nullOr (enum ["always", "whenUnlocked", "never"])`

**Default:** `null`

**Description:** Controls when to show notification previews.

**Example:**
```nix
systemSettings.notifications.notificationCenter.showPreviews = "whenUnlocked";
```

##### `systemSettings.notifications.notificationCenter.summarizeNotifications`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to summarize notifications in Notification Center.

**Example:**
```nix
systemSettings.notifications.notificationCenter.summarizeNotifications = true;
```

### Sound

#### Sound Effects

##### `systemSettings.sound.soundEffects.alertSound`

**Type:** `nullOr (enum ["Boop", "Breeze", "Bubble", "Crystal", "Funky", "Heroine", "Jump", "Mezzo", "Pebble", "Pluck", "Pong", "Sonar", "Sonumi", "Submerge"])`

**Default:** `null`

**Description:** Sets the alert sound for system notifications.

**Example:**
```nix
systemSettings.sound.soundEffects.alertSound = "Crystal";
```

##### `systemSettings.sound.soundEffects.alertVolume`

**Type:** `nullOr (floatBetween 0.0 1.0)`

**Default:** `null`

**Description:** Sets the volume level for alert sounds.

**Example:**
```nix
systemSettings.sound.soundEffects.alertVolume = 0.7;
```

##### `systemSettings.sound.soundEffects.playUserInterfaceSoundEffects`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to play user interface sound effects.

**Example:**
```nix
systemSettings.sound.soundEffects.playUserInterfaceSoundEffects = true;
```

##### `systemSettings.sound.soundEffects.playFeedbackWhenVolumeIsChanged`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to play feedback sounds when volume is changed.

**Example:**
```nix
systemSettings.sound.soundEffects.playFeedbackWhenVolumeIsChanged = true;
```

### Spotlight

#### Search Results

##### `systemSettings.spotlight.searchResults.applications`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include applications in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.applications = false;
```

##### `systemSettings.spotlight.searchResults.calculator`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include calculator in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.calculator = true;
```

##### `systemSettings.spotlight.searchResults.contacts`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include contacts in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.contacts = true;
```

##### `systemSettings.spotlight.searchResults.conversion`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include unit conversions in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.conversion = true;
```

##### `systemSettings.spotlight.searchResults.definition`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include dictionary definitions in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.definition = true;
```

##### `systemSettings.spotlight.searchResults.developer`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include developer resources in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.developer = false;
```

##### `systemSettings.spotlight.searchResults.documents`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include documents in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.documents = true;
```

##### `systemSettings.spotlight.searchResults.eventsAndReminders`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include events and reminders in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.eventsAndReminders = true;
```

##### `systemSettings.spotlight.searchResults.folders`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include folders in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.folders = true;
```

##### `systemSettings.spotlight.searchResults.fonts`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include fonts in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.fonts = false;
```

##### `systemSettings.spotlight.searchResults.images`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include images in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.images = true;
```

##### `systemSettings.spotlight.searchResults.mailAndMessages`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include mail and messages in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.mailAndMessages = true;
```

##### `systemSettings.spotlight.searchResults.movies`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include movies in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.movies = true;
```

##### `systemSettings.spotlight.searchResults.music`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include music in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.music = true;
```

##### `systemSettings.spotlight.searchResults.other`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include other items in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.other = false;
```

##### `systemSettings.spotlight.searchResults.pdfDocuments`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include PDF documents in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.pdfDocuments = true;
```

##### `systemSettings.spotlight.searchResults.presentations`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include presentations in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.presentations = true;
```

##### `systemSettings.spotlight.searchResults.siriSuggestions`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include Siri suggestions in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.siriSuggestions = false;
```

##### `systemSettings.spotlight.searchResults.systemSettings`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include system settings in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.systemSettings = true;
```

##### `systemSettings.spotlight.searchResults.tips`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include tips in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.tips = false;
```

##### `systemSettings.spotlight.searchResults.websites`

**Type:** `nullOr bool`

**Default:** `true`

**Description:** Whether to include websites in Spotlight search results.

**Example:**
```nix
systemSettings.spotlight.searchResults.websites = true;
```

##### `systemSettings.spotlight.helpAppleImproveSearch`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to help Apple improve search by sending usage data.

**Example:**
```nix
systemSettings.spotlight.helpAppleImproveSearch = false;
```

### Trackpad

#### `systemSettings.trackpad.trackingSpeed`

**Type:** `nullOr (ints.between 1 10)`

**Default:** `null`

**Description:** Sets the tracking speed of the trackpad (higher numbers = faster).

**Example:**
```nix
systemSettings.trackpad.trackingSpeed = 5;
```

#### `systemSettings.trackpad.click`

**Type:** `nullOr (enum ["Light", "Medium", "Firm"])`

**Default:** `null`

**Description:** Sets the click pressure for the trackpad.

**Example:**
```nix
systemSettings.trackpad.click = "Medium";
```

#### `systemSettings.trackpad.forceClickAndHapticFeedback`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to enable force click and haptic feedback.

**Example:**
```nix
systemSettings.trackpad.forceClickAndHapticFeedback = true;
```

#### `systemSettings.trackpad.tapToClick`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to enable tap to click.

**Example:**
```nix
systemSettings.trackpad.tapToClick = true;
```

## Applications

### Finder

#### `applications.finder.removeItemsFromTheTrashAfter30Days`

**Type:** `nullOr bool`

**Default:** `null`

**Description:** Whether to automatically remove items from the Trash after 30 days.

**Example:**
```nix
applications.finder.removeItemsFromTheTrashAfter30Days = true;
```