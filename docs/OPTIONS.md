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

**Type:** `nullOr (enum ["Light" "Dark" "Auto"])`

**Default:** `null`

**Example:**
```nix
systemSettings.appearance = "Dark";
```

#### `systemSettings.accentColor`

**Type:** `nullOr (enum ["Graphite" "Red" "Orange" "Yellow" "Green" "Blue" "Purple" "Pink" "Multicolor"])`

**Default:** `null`

**Example:**
```nix
systemSettings.accentColor = "Blue";
```

#### `systemSettings.sidebarIconSize`

**Type:** `nullOr (enum ["Small" "Medium" "Large"])`

**Default:** `null`

**Example:**
```nix
systemSettings.sidebarIconSize = "Medium";
```

#### `systemSettings.allowWallpaperTintingInWindows`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.allowWallpaperTintingInWindows = true;
```

#### `systemSettings.showScrollBars`

**Type:** `nullOr (enum ["Automatically based on mouse or trackpad" "When scrolling" "Always"])`

**Default:** `null`

**Example:**
```nix
systemSettings.showScrollBars = "Always";
```

#### `systemSettings.clickInTheScrollBarTo`

**Type:** `nullOr (enum ["Jump to the next page" "Jump to the spot that's clicked"])`

**Default:** `null`

**Example:**
```nix
systemSettings.clickInTheScrollBarTo = "Jump to the spot that's clicked";
```

### Control Center

#### `systemSettings.controlCenter.wifi`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.controlCenter.wifi = true;
```

#### `systemSettings.controlCenter.bluetooth`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.controlCenter.bluetooth = true;
```

#### `systemSettings.controlCenter.airdrop`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.controlCenter.airdrop = true;
```

#### `systemSettings.controlCenter.stageManager`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.controlCenter.stageManager = true;
```

#### `systemSettings.controlCenter.focusModes`

**Type:** `nullOr (enum ["always" "active" "never"])`

**Default:** `null`

**Example:**
```nix
systemSettings.controlCenter.focusModes = "always";
```

#### `systemSettings.controlCenter.screenMirroring`

**Type:** `nullOr (enum ["always" "active" "never"])`

**Default:** `null`

**Example:**
```nix
systemSettings.controlCenter.screenMirroring = "active";
```

#### `systemSettings.controlCenter.display`

**Type:** `nullOr (enum ["always" "active" "never"])`

**Default:** `null`

**Example:**
```nix
systemSettings.controlCenter.display = "always";
```

#### `systemSettings.controlCenter.sound`

**Type:** `nullOr (enum ["always" "active" "never"])`

**Default:** `null`

**Example:**
```nix
systemSettings.controlCenter.sound = "always";
```

#### `systemSettings.controlCenter.nowPlaying`

**Type:** `nullOr (enum ["always" "active" "never"])`

**Default:** `null`

**Example:**
```nix
systemSettings.controlCenter.nowPlaying = "active";
```

#### `systemSettings.controlCenter.accessibilityShortcuts`

**Type:** `nullOr (submodule { showInMenuBar = nullOr bool; showInControlCenter = nullOr bool; })`

**Default:** `null`

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

**Example:**
```nix
systemSettings.controlCenter.batteryShowPercentage = true;
```

#### `systemSettings.controlCenter.menuBarOnly.spotlight`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.controlCenter.menuBarOnly.spotlight = false;
```

#### `systemSettings.controlCenter.menuBarOnly.siri`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.controlCenter.menuBarOnly.siri = true;
```

#### `systemSettings.controlCenter.automaticallyHideAndShowTheMenuBar`

**Type:** `nullOr (enum ["Always" "On Desktop Only" "In Full Screen Only" "Never"])`

**Default:** `null`

**Example:**
```nix
systemSettings.controlCenter.automaticallyHideAndShowTheMenuBar = "Always";
```

### Desktop & Dock

#### Dock Options

##### `systemSettings.desktopAndDock.dock.size`

**Type:** `nullOr (ints.between 16 128)`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.dock.size = 64;
```

##### `systemSettings.desktopAndDock.dock.magnification`

**Type:** `nullOr (submodule { enabled = nullOr bool; size = nullOr (ints.between 30 128); })`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.dock.magnification = {
  enabled = true;
  size = 64;
};
```

##### `systemSettings.desktopAndDock.dock.positionOnScreen`

**Type:** `nullOr (enum ["Left" "Bottom" "Right"])`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.dock.positionOnScreen = "Bottom";
```

##### `systemSettings.desktopAndDock.dock.minimizeWindowsUsing`

**Type:** `nullOr (enum ["Genie Effect" "Scale Effect"])`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.dock.minimizeWindowsUsing = "Genie Effect";
```

##### `systemSettings.desktopAndDock.dock.doubleClickAWindowsTitleBarTo`

**Type:** `nullOr (enum ["Fill" "Zoom" "Minimize" "Do nothing"])`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.dock.doubleClickAWindowsTitleBarTo = "Zoom";
```

##### `systemSettings.desktopAndDock.dock.minimizeWindowsIntoApplicationIcon`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.dock.minimizeWindowsIntoApplicationIcon = true;
```

##### `systemSettings.desktopAndDock.dock.automaticallyHideAndShowTheDock`

**Type:** `nullOr (submodule { enabled = nullOr bool; delay = nullOr float; duration = nullOr float; })`

**Default:** `null`

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

**Example:**
```nix
systemSettings.desktopAndDock.dock.animateOpeningApplications = true;
```

##### `systemSettings.desktopAndDock.dock.showIndicatorsForOpenApplications`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.dock.showIndicatorsForOpenApplications = true;
```

##### `systemSettings.desktopAndDock.dock.showSuggestedAndRecentAppsInDock`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.dock.showSuggestedAndRecentAppsInDock = false;
```

##### `systemSettings.desktopAndDock.dock.persistentApps`

**Type:** `nullOr (listOf taggedType)`

**Default:** `null`

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

**Example:**
```nix
systemSettings.desktopAndDock.desktopAndStageManager.showItems = {
  onDesktop = true;
  inStageManager = false;
};
```

##### `systemSettings.desktopAndDock.desktopAndStageManager.clickWallpaperToRevealDesktop`

**Type:** `nullOr (enum ["Always" "Only in Stage Manager"])`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.desktopAndStageManager.clickWallpaperToRevealDesktop = "Always";
```

##### `systemSettings.desktopAndDock.desktopAndStageManager.stageManager`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.desktopAndStageManager.stageManager = true;
```

##### `systemSettings.desktopAndDock.desktopAndStageManager.showRecentAppsInStageManager`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.desktopAndStageManager.showRecentAppsInStageManager = true;
```

##### `systemSettings.desktopAndDock.desktopAndStageManager.showWindowsFromAnApplication`

**Type:** `nullOr (enum ["allAtOnce" "oneAtATime"])`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.desktopAndStageManager.showWindowsFromAnApplication = "allAtOnce";
```

#### Widgets

##### `systemSettings.desktopAndDock.widgets.showWidgets`

**Type:** `nullOr (submodule { onDesktop = nullOr bool; inStageManager = nullOr bool; })`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.widgets.showWidgets = {
  onDesktop = true;
  inStageManager = false;
};
```

##### `systemSettings.desktopAndDock.widgets.widgetStyle`

**Type:** `nullOr (enum ["automatic" "monochrome" "full-color"])`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.widgets.widgetStyle = "automatic";
```

##### `systemSettings.desktopAndDock.widgets.useIphoneWidgets`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.widgets.useIphoneWidgets = true;
```

#### Windows

##### `systemSettings.desktopAndDock.windows.preferTabsWhenOpeningDocuments`

**Type:** `nullOr (enum ["never" "always" "inFullScreen"])`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.windows.preferTabsWhenOpeningDocuments = "always";
```

##### `systemSettings.desktopAndDock.windows.askToKeepChangesWhenClosingDocuments`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.windows.askToKeepChangesWhenClosingDocuments = true;
```

##### `systemSettings.desktopAndDock.windows.closeWindowsWhenQuittingAnApplication`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.windows.closeWindowsWhenQuittingAnApplication = false;
```

##### `systemSettings.desktopAndDock.windows.dragWindowsToScreenEdgesToTile`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.windows.dragWindowsToScreenEdgesToTile = true;
```

##### `systemSettings.desktopAndDock.windows.dragWindowsToMenuBarToFillScreen`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.windows.dragWindowsToMenuBarToFillScreen = true;
```

##### `systemSettings.desktopAndDock.windows.holdOptionKeyWhileDraggingWindowsToTile`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.windows.holdOptionKeyWhileDraggingWindowsToTile = false;
```

##### `systemSettings.desktopAndDock.windows.tiledWindowsHaveMargin`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.windows.tiledWindowsHaveMargin = true;
```

#### Mission Control

##### `systemSettings.desktopAndDock.missionControl.automaticallyRearrangeSpacesBasedOnMostRecentUse`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.missionControl.automaticallyRearrangeSpacesBasedOnMostRecentUse = true;
```

##### `systemSettings.desktopAndDock.missionControl.whenSwitchingToAnApplicationSwitchToAspaceWithOpenWindowsForTheApplication`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.missionControl.whenSwitchingToAnApplicationSwitchToAspaceWithOpenWindowsForTheApplication = true;
```

##### `systemSettings.desktopAndDock.missionControl.groupWindowsByApplication`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.missionControl.groupWindowsByApplication = true;
```

##### `systemSettings.desktopAndDock.missionControl.displaysHaveSeparateSpaces`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.missionControl.displaysHaveSeparateSpaces = true;
```

##### `systemSettings.desktopAndDock.missionControl.dragWindowsToTopOfScreenToEnterMissionControl`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.missionControl.dragWindowsToTopOfScreenToEnterMissionControl = true;
```

#### Hot Corners

##### `systemSettings.desktopAndDock.hotCorners.topLeft`

**Type:** `nullOr (enum ["disabled" "missionControl" "applicationWindows" "desktop" "startScreenSaver" "disableScreenSaver" "dashboard" "putDisplayToSleep" "launchpad" "notificationCenter" "lockScreen" "quickNote"])`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.hotCorners.topLeft = "missionControl";
```

##### `systemSettings.desktopAndDock.hotCorners.topRight`

**Type:** `nullOr (enum ["disabled" "missionControl" "applicationWindows" "desktop" "startScreenSaver" "disableScreenSaver" "dashboard" "putDisplayToSleep" "launchpad" "notificationCenter" "lockScreen" "quickNote"])`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.hotCorners.topRight = "desktop";
```

##### `systemSettings.desktopAndDock.hotCorners.bottomLeft`

**Type:** `nullOr (enum ["disabled" "missionControl" "applicationWindows" "desktop" "startScreenSaver" "disableScreenSaver" "dashboard" "putDisplayToSleep" "launchpad" "notificationCenter" "lockScreen" "quickNote"])`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.hotCorners.bottomLeft = "launchpad";
```

##### `systemSettings.desktopAndDock.hotCorners.bottomRight`

**Type:** `nullOr (enum ["disabled" "missionControl" "applicationWindows" "desktop" "startScreenSaver" "disableScreenSaver" "dashboard" "putDisplayToSleep" "launchpad" "notificationCenter" "lockScreen" "quickNote"])`

**Default:** `null`

**Example:**
```nix
systemSettings.desktopAndDock.hotCorners.bottomRight = "notificationCenter";
```

### Focus

#### `systemSettings.focus.shareAcrossDevices`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.focus.shareAcrossDevices = false;
```

### General

#### Software Update

##### `systemSettings.general.softwareUpdate.automaticallyDownloadNewUpdatesWhenAvailable`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.general.softwareUpdate.automaticallyDownloadNewUpdatesWhenAvailable = true;
```

##### `systemSettings.general.softwareUpdate.automaticallyInstallMacOSUpdates`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.general.softwareUpdate.automaticallyInstallMacOSUpdates = false;
```

##### `systemSettings.general.softwareUpdate.automaticallyInstallApplicationUpdatesFromTheAppStore`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.general.softwareUpdate.automaticallyInstallApplicationUpdatesFromTheAppStore = true;
```

##### `systemSettings.general.softwareUpdate.automaticallyInstallSecurityResponseAndSystemFiles`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.general.softwareUpdate.automaticallyInstallSecurityResponseAndSystemFiles = true;
```

#### Date & Time

##### `systemSettings.general.dateAndTime.setTimeAndDateAutomatically`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.general.dateAndTime.setTimeAndDateAutomatically = true;
```

##### `systemSettings.general.dateAndTime."24HourTime"`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.general.dateAndTime."24HourTime" = true;
```

##### `systemSettings.general.dateAndTime.show24HourTimeOnLockScreen`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.general.dateAndTime.show24HourTimeOnLockScreen = true;
```

##### `systemSettings.general.dateAndTime.setTimeZoneAutomaticallyUsingCurrentLocation`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.general.dateAndTime.setTimeZoneAutomaticallyUsingCurrentLocation = true;
```

### Keyboard

#### `systemSettings.keyboard.keyRepeatRate`

**Type:** `nullOr (ints.between 1 7)`

**Default:** `null`

**Example:**
```nix
systemSettings.keyboard.keyRepeatRate = 3;
```

#### `systemSettings.keyboard.keyRepeatDelay`

**Type:** `nullOr (ints.between 1 6)`

**Default:** `null`

**Example:**
```nix
systemSettings.keyboard.keyRepeatDelay = 2;
```

#### `systemSettings.keyboard.adjustKeyboardBrightnessInLowLight`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.keyboard.adjustKeyboardBrightnessInLowLight = true;
```

#### `systemSettings.keyboard.keyboardBrightness`

**Type:** `nullOr (floatBetween 0.0 1.0)`

**Default:** `null`

**Example:**
```nix
systemSettings.keyboard.keyboardBrightness = 0.5;
```

#### `systemSettings.keyboard.turnKeyboardBacklightOffAfterInactivity`

**Type:** `nullOr (enum ["After 5 Seconds" "After 10 Seconds" "After 30 Seconds" "After 1 Minute" "After 5 Minutes" "Never"])`

**Default:** `null`

**Example:**
```nix
systemSettings.keyboard.turnKeyboardBacklightOffAfterInactivity = "After 1 Minute";
```

#### `systemSettings.keyboard.pressGlobeKeyTo`

**Type:** `nullOr (enum ["Change Input Source" "Show Emoji & Symbols" "Start Dictation (Press Globe Key Twice)" "Do Nothing"])`

**Default:** `null`

**Example:**
```nix
systemSettings.keyboard.pressGlobeKeyTo = "Show Emoji & Symbols";
```

#### `systemSettings.keyboard.keyboardNavigation`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.keyboard.keyboardNavigation = true;
```

#### Keyboard Shortcuts

##### `systemSettings.keyboard.keyboardShortcuts.functionKeys.useF1F2EtcAsStandardFunctionKeys`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.keyboard.keyboardShortcuts.functionKeys.useF1F2EtcAsStandardFunctionKeys = true;
```

#### Dictation

##### `systemSettings.keyboard.dictation.enabled`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.keyboard.dictation.enabled = true;
```

### Notifications

#### Notification Center

##### `systemSettings.notifications.notificationCenter.showPreviews`

**Type:** `nullOr (enum ["always" "whenUnlocked" "never"])`

**Default:** `null`

**Example:**
```nix
systemSettings.notifications.notificationCenter.showPreviews = "whenUnlocked";
```

##### `systemSettings.notifications.notificationCenter.summarizeNotifications`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.notifications.notificationCenter.summarizeNotifications = true;
```

### Sound

#### Sound Effects

##### `systemSettings.sound.soundEffects.alertSound`

**Type:** `nullOr (enum ["Boop" "Breeze" "Bubble" "Crystal" "Funky" "Heroine" "Jump" "Mezzo" "Pebble" "Pluck" "Pong" "Sonar" "Sonumi" "Submerge"])`

**Default:** `null`

**Example:**
```nix
systemSettings.sound.soundEffects.alertSound = "Crystal";
```

##### `systemSettings.sound.soundEffects.alertVolume`

**Type:** `nullOr (floatBetween 0.0 1.0)`

**Default:** `null`

**Example:**
```nix
systemSettings.sound.soundEffects.alertVolume = 0.7;
```

##### `systemSettings.sound.soundEffects.playUserInterfaceSoundEffects`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.sound.soundEffects.playUserInterfaceSoundEffects = true;
```

##### `systemSettings.sound.soundEffects.playFeedbackWhenVolumeIsChanged`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.sound.soundEffects.playFeedbackWhenVolumeIsChanged = true;
```

### Spotlight

#### Search Results

##### `systemSettings.spotlight.searchResults.applications`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.applications = false;
```

##### `systemSettings.spotlight.searchResults.calculator`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.calculator = true;
```

##### `systemSettings.spotlight.searchResults.contacts`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.contacts = true;
```

##### `systemSettings.spotlight.searchResults.conversion`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.conversion = true;
```

##### `systemSettings.spotlight.searchResults.definition`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.definition = true;
```

##### `systemSettings.spotlight.searchResults.developer`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.developer = false;
```

##### `systemSettings.spotlight.searchResults.documents`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.documents = true;
```

##### `systemSettings.spotlight.searchResults.eventsAndReminders`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.eventsAndReminders = true;
```

##### `systemSettings.spotlight.searchResults.folders`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.folders = true;
```

##### `systemSettings.spotlight.searchResults.fonts`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.fonts = false;
```

##### `systemSettings.spotlight.searchResults.images`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.images = true;
```

##### `systemSettings.spotlight.searchResults.mailAndMessages`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.mailAndMessages = true;
```

##### `systemSettings.spotlight.searchResults.movies`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.movies = true;
```

##### `systemSettings.spotlight.searchResults.music`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.music = true;
```

##### `systemSettings.spotlight.searchResults.other`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.other = false;
```

##### `systemSettings.spotlight.searchResults.pdfDocuments`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.pdfDocuments = true;
```

##### `systemSettings.spotlight.searchResults.presentations`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.presentations = true;
```

##### `systemSettings.spotlight.searchResults.siriSuggestions`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.siriSuggestions = false;
```

##### `systemSettings.spotlight.searchResults.systemSettings`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.systemSettings = true;
```

##### `systemSettings.spotlight.searchResults.tips`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.tips = false;
```

##### `systemSettings.spotlight.searchResults.websites`

**Type:** `nullOr bool`

**Default:** `true`

**Example:**
```nix
systemSettings.spotlight.searchResults.websites = true;
```

##### `systemSettings.spotlight.helpAppleImproveSearch`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.spotlight.helpAppleImproveSearch = false;
```

### Trackpad

#### `systemSettings.trackpad.trackingSpeed`

**Type:** `nullOr (ints.between 1 10)`

**Default:** `null`

**Example:**
```nix
systemSettings.trackpad.trackingSpeed = 5;
```

#### `systemSettings.trackpad.click`

**Type:** `nullOr (enum ["Light" "Medium" "Firm"])`

**Default:** `null`

**Example:**
```nix
systemSettings.trackpad.click = "Medium";
```

#### `systemSettings.trackpad.forceClickAndHapticFeedback`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.trackpad.forceClickAndHapticFeedback = true;
```

#### `systemSettings.trackpad.tapToClick`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
systemSettings.trackpad.tapToClick = true;
```

## Applications

### Finder

#### `applications.finder.removeItemsFromTheTrashAfter30Days`

**Type:** `nullOr bool`

**Default:** `null`

**Example:**
```nix
applications.finder.removeItemsFromTheTrashAfter30Days = true;
```
