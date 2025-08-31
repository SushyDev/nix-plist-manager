# Nix Plist Manager Options Documentation

This document lists all available options in the `modules/systemSettings` and `modules/applications` directories, including their types, possible values, and examples.

## System Settings

### Appearance (`modules/systemSettings/appearance.nix`)

- **appearance**
  - Type: `nullOr (enum ["Light", "Dark", "Auto"])`
  - Default: `null`
  - Example: `systemSettings.appearance = "Dark";`

- **accentColor**
  - Type: `nullOr (enum ["Graphite", "Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Pink", "Multicolor"])`
  - Default: `null`
  - Example: `systemSettings.accentColor = "Blue";`

- **sidebarIconSize**
  - Type: `nullOr (enum ["Small", "Medium", "Large"])`
  - Default: `null`
  - Example: `systemSettings.sidebarIconSize = "Medium";`

- **allowWallpaperTintingInWindows**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.allowWallpaperTintingInWindows = true;`

- **showScrollBars**
  - Type: `nullOr (enum ["Automatically based on mouse or trackpad", "When scrolling", "Always"])`
  - Default: `null`
  - Example: `systemSettings.showScrollBars = "Always";`

- **clickInTheScrollBarTo**
  - Type: `nullOr (enum ["Jump to the next page", "Jump to the spot that's clicked"])`
  - Default: `null`
  - Example: `systemSettings.clickInTheScrollBarTo = "Jump to the spot that's clicked";`

### Control Center (`modules/systemSettings/control-center.nix`)

#### Bool Modules (show in menu bar)
- **wifi**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.controlCenter.wifi = true;`

- **bluetooth**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.controlCenter.bluetooth = true;`

- **airdrop**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.controlCenter.airdrop = true;`

- **stageManager**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.controlCenter.stageManager = true;`

#### Enum Modules
- **focusModes**
  - Type: `nullOr (enum ["always", "active", "never"])`
  - Default: `null`
  - Example: `systemSettings.controlCenter.focusModes = "always";`

- **screenMirroring**
  - Type: `nullOr (enum ["always", "active", "never"])`
  - Default: `null`
  - Example: `systemSettings.controlCenter.screenMirroring = "active";`

- **display**
  - Type: `nullOr (enum ["always", "active", "never"])`
  - Default: `null`
  - Example: `systemSettings.controlCenter.display = "always";`

- **sound**
  - Type: `nullOr (enum ["always", "active", "never"])`
  - Default: `null`
  - Example: `systemSettings.controlCenter.sound = "always";`

- **nowPlaying**
  - Type: `nullOr (enum ["always", "active", "never"])`
  - Default: `null`
  - Example: `systemSettings.controlCenter.nowPlaying = "active";`

#### Bitmap Modules (submodule with showInMenuBar and showInControlCenter)
- **accessibilityShortcuts**
  - Type: `nullOr (submodule { showInMenuBar = nullOr bool; showInControlCenter = nullOr bool; })`
  - Default: `null`
  - Example: `systemSettings.controlCenter.accessibilityShortcuts = { showInMenuBar = true; showInControlCenter = false; };`

- **musicRecognition**
  - Type: `nullOr (submodule { showInMenuBar = nullOr bool; showInControlCenter = nullOr bool; })`
  - Default: `null`
  - Example: `systemSettings.controlCenter.musicRecognition = { showInMenuBar = true; showInControlCenter = true; };`

- **hearing**
  - Type: `nullOr (submodule { showInMenuBar = nullOr bool; showInControlCenter = nullOr bool; })`
  - Default: `null`
  - Example: `systemSettings.controlCenter.hearing = { showInMenuBar = false; showInControlCenter = true; };`

- **fastUserSwitching**
  - Type: `nullOr (submodule { showInMenuBar = nullOr bool; showInControlCenter = nullOr bool; })`
  - Default: `null`
  - Example: `systemSettings.controlCenter.fastUserSwitching = { showInMenuBar = true; showInControlCenter = false; };`

- **keyboardBrightness**
  - Type: `nullOr (submodule { showInMenuBar = nullOr bool; showInControlCenter = nullOr bool; })`
  - Default: `null`
  - Example: `systemSettings.controlCenter.keyboardBrightness = { showInMenuBar = false; showInControlCenter = true; };`

#### Special Options
- **battery**
  - Type: `nullOr (submodule { showInMenuBar = nullOr bool; showInControlCenter = nullOr bool; })`
  - Default: `null`
  - Example: `systemSettings.controlCenter.battery = { showInMenuBar = true; showInControlCenter = true; };`

- **batteryShowPercentage**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.controlCenter.batteryShowPercentage = true;`

- **menuBarOnly.spotlight**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.controlCenter.menuBarOnly.spotlight = false;`

- **menuBarOnly.siri**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.controlCenter.menuBarOnly.siri = true;`

- **automaticallyHideAndShowTheMenuBar**
  - Type: `nullOr (enum ["Always", "On Desktop Only", "In Full Screen Only", "Never"])`
  - Default: `null`
  - Example: `systemSettings.controlCenter.automaticallyHideAndShowTheMenuBar = "Always";`

### Desktop & Dock (`modules/systemSettings/desktop-and-dock.nix`)

#### Dock
- **dock.size**
  - Type: `nullOr (ints.between 16 128)`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.dock.size = 64;`

- **dock.magnification**
  - Type: `nullOr (submodule { enabled = nullOr bool; size = nullOr (ints.between 30 128); })`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.dock.magnification = { enabled = true; size = 64; };`

- **dock.positionOnScreen**
  - Type: `nullOr (enum ["left", "bottom", "right"])`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.dock.positionOnScreen = "bottom";`

- **dock.minimizeWindowsUsing**
  - Type: `nullOr (enum ["genie", "scale"])`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.dock.minimizeWindowsUsing = "genie";`

- **dock.doubleClickAWindowsTitleBarTo**
  - Type: `nullOr (enum ["fill", "zoom", "minimize", "doNothing"])`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.dock.doubleClickAWindowsTitleBarTo = "zoom";`

- **dock.minimizeWindowsIntoApplicationIcon**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.dock.minimizeWindowsIntoApplicationIcon = true;`

- **dock.automaticallyHideAndShowTheDock**
  - Type: `nullOr (submodule { enabled = nullOr bool; delay = nullOr float; duration = nullOr float; })`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.dock.automaticallyHideAndShowTheDock = { enabled = true; delay = 0.5; duration = 0.3; };`

- **dock.animateOpeningApplications**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.dock.animateOpeningApplications = true;`

- **dock.showIndicatorsForOpenApplications**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.dock.showIndicatorsForOpenApplications = true;`

- **dock.showSuggestedAndRecentAppsInDock**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.dock.showSuggestedAndRecentAppsInDock = false;`

- **dock.persistentApps**
  - Type: `nullOr (listOf taggedType)`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.dock.persistentApps = [ { app = "/Applications/Safari.app"; } ];`

- **dock.persistentOthers**
  - Type: `nullOr (listOf (either path str))`
  - Default: `null`
  - Example: `systemSettings.desktopAndDock.dock.persistentOthers = [ "~/Documents" ];`

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

### Focus (`modules/systemSettings/focus.nix`)

- **shareAcrossDevices**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.focus.shareAcrossDevices = false;`

### General (`modules/systemSettings/general.nix`)

#### Software Update
- **softwareUpdate.automaticallyDownloadNewUpdatesWhenAvailable**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.general.softwareUpdate.automaticallyDownloadNewUpdatesWhenAvailable = true;`

- **softwareUpdate.automaticallyInstallMacOSUpdates**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.general.softwareUpdate.automaticallyInstallMacOSUpdates = false;`

- **softwareUpdate.automaticallyInstallApplicationUpdatesFromTheAppStore**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.general.softwareUpdate.automaticallyInstallApplicationUpdatesFromTheAppStore = true;`

- **softwareUpdate.automaticallyInstallSecurityResponseAndSystemFiles**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.general.softwareUpdate.automaticallyInstallSecurityResponseAndSystemFiles = true;`

#### Date & Time
- **dateAndTime.setTimeAndDateAutomatically**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.general.dateAndTime.setTimeAndDateAutomatically = true;`

- **dateAndTime."24HourTime"**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.general.dateAndTime."24HourTime" = true;`

- **dateAndTime.show24HourTimeOnLockScreen**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.general.dateAndTime.show24HourTimeOnLockScreen = true;`

- **dateAndTime.setTimeZoneAutomaticallyUsingCurrentLocation**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.general.dateAndTime.setTimeZoneAutomaticallyUsingCurrentLocation = true;`

### Keyboard (`modules/systemSettings/keyboard.nix`)

- **keyRepeatRate**
  - Type: `nullOr (ints.between 1 7)`
  - Default: `null`
  - Example: `systemSettings.keyboard.keyRepeatRate = 3;`

- **keyRepeatDelay**
  - Type: `nullOr (ints.between 1 6)`
  - Default: `null`
  - Example: `systemSettings.keyboard.keyRepeatDelay = 2;`

- **adjustKeyboardBrightnessInLowLight**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.keyboard.adjustKeyboardBrightnessInLowLight = true;`

- **keyboardBrightness**
  - Type: `nullOr (floatBetween 0.0 1.0)`
  - Default: `null`
  - Example: `systemSettings.keyboard.keyboardBrightness = 0.5;`

- **turnKeyboardBacklightOffAfterInactivity**
  - Type: `nullOr (enum ["After 5 Seconds", "After 10 Seconds", "After 30 Seconds", "After 1 Minute", "After 5 Minutes", "Never"])`
  - Default: `null`
  - Example: `systemSettings.keyboard.turnKeyboardBacklightOffAfterInactivity = "After 1 Minute";`

- **pressGlobeKeyTo**
  - Type: `nullOr (enum ["Change Input Source", "Show Emoji & Symbols", "Start Dictation (Press Globe Key Twice)", "Do Nothing"])`
  - Default: `null`
  - Example: `systemSettings.keyboard.pressGlobeKeyTo = "Show Emoji & Symbols";`

- **keyboardNavigation**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.keyboard.keyboardNavigation = true;`

#### Keyboard Shortcuts
- **keyboardShortcuts.functionKeys.useF1F2EtcAsStandardFunctionKeys**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.keyboard.keyboardShortcuts.functionKeys.useF1F2EtcAsStandardFunctionKeys = true;`

#### Dictation
- **dictation.enabled**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.keyboard.dictation.enabled = true;`

### Notifications (`modules/systemSettings/notifications.nix`)

#### Notification Center
- **notificationCenter.showPreviews**
  - Type: `nullOr (enum ["always", "whenUnlocked", "never"])`
  - Default: `null`
  - Example: `systemSettings.notifications.notificationCenter.showPreviews = "whenUnlocked";`

- **notificationCenter.summarizeNotifications**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.notifications.notificationCenter.summarizeNotifications = true;`

### Sound (`modules/systemSettings/sound.nix`)

#### Sound Effects
- **soundEffects.alertSound**
  - Type: `nullOr (enum ["Boop", "Breeze", "Bubble", "Crystal", "Funky", "Heroine", "Jump", "Mezzo", "Pebble", "Pluck", "Pong", "Sonar", "Sonumi", "Submerge"])`
  - Default: `null`
  - Example: `systemSettings.sound.soundEffects.alertSound = "Crystal";`

- **soundEffects.alertVolume**
  - Type: `nullOr (floatBetween 0.0 1.0)`
  - Default: `null`
  - Example: `systemSettings.sound.soundEffects.alertVolume = 0.7;`

- **soundEffects.playUserInterfaceSoundEffects**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.sound.soundEffects.playUserInterfaceSoundEffects = true;`

- **soundEffects.playFeedbackWhenVolumeIsChanged**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.sound.soundEffects.playFeedbackWhenVolumeIsChanged = true;`

### Spotlight (`modules/systemSettings/spotlight.nix`)

#### Search Results
- **searchResults.applications**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.applications = false;`

- **searchResults.calculator**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.calculator = true;`

- **searchResults.contacts**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.contacts = true;`

- **searchResults.conversion**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.conversion = true;`

- **searchResults.definition**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.definition = true;`

- **searchResults.developer**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.developer = false;`

- **searchResults.documents**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.documents = true;`

- **searchResults.eventsAndReminders**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.eventsAndReminders = true;`

- **searchResults.folders**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.folders = true;`

- **searchResults.fonts**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.fonts = false;`

- **searchResults.images**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.images = true;`

- **searchResults.mailAndMessages**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.mailAndMessages = true;`

- **searchResults.movies**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.movies = true;`

- **searchResults.music**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.music = true;`

- **searchResults.other**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.other = false;`

- **searchResults.pdfDocuments**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.pdfDocuments = true;`

- **searchResults.presentations**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.presentations = true;`

- **searchResults.siriSuggestions**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.siriSuggestions = false;`

- **searchResults.systemSettings**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.systemSettings = true;`

- **searchResults.tips**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.tips = false;`

- **searchResults.websites**
  - Type: `nullOr bool`
  - Default: `true`
  - Example: `systemSettings.spotlight.searchResults.websites = true;`

- **helpAppleImproveSearch**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.spotlight.helpAppleImproveSearch = false;`

### Trackpad (`modules/systemSettings/trackpad.nix`)

- **trackingSpeed**
  - Type: `nullOr (ints.between 1 10)`
  - Default: `null`
  - Example: `systemSettings.trackpad.trackingSpeed = 5;`

- **click**
  - Type: `nullOr (enum ["Light", "Medium", "Firm"])`
  - Default: `null`
  - Example: `systemSettings.trackpad.click = "Medium";`

- **forceClickAndHapticFeedback**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.trackpad.forceClickAndHapticFeedback = true;`

- **tapToClick**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `systemSettings.trackpad.tapToClick = true;`

## Applications

### Finder (`modules/applications/finder.nix`)

- **removeItemsFromTheTrashAfter30Days**
  - Type: `nullOr bool`
  - Default: `null`
  - Example: `applications.finder.removeItemsFromTheTrashAfter30Days = true;`