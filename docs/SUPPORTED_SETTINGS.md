# Supported Settings

This document outlines all the macOS system settings that can be configured through the nix-plist-manager module. Settings are organized hierarchically to match the macOS System Settings app structure.

Legend:
- [x] Implemented
- [ ] Not yet implemented

## System Settings

### General
- [x] Software Update
  - [x] Automatically download new updates when available
  - [x] Install macOS updates
  - [x] Install application updates from the App Store
  - [x] Install Security Response and system files
- [x] Date & Time
  - [x] Set time and date automatically
  - [x] 24-hour time
  - [x] Show 24-hour time on lock screen
  - [x] Set time zone automatically using current location

### Appearance
- [x] Appearance (Light/Dark/Auto)
- [x] Accent Color (Graphite/Red/Orange/Yellow/Green/Blue/Purple/Pink/Multicolor)
- [ ] Highlight color
- [x] Sidebar icon size (Small/Medium/Large)
- [x] Allow wallpaper tinting in windows
- [x] Show scroll bars (Automatically/When scrolling/Always)
- [x] Click in the scroll bar to (Jump to next page/Jump to spot clicked)

### Control Center
- [x] Wi-Fi
- [x] Bluetooth
- [x] AirDrop
- [x] Stage Manager
- [x] Focus
- [x] Screen Mirroring
- [x] Display
- [x] Sound
- [x] Now Playing
- [x] Accessibility Shortcuts
- [x] Music Recognition
- [x] Hearing
- [x] User Switcher
- [x] Keyboard Brightness
- [x] Battery
- [x] Battery > Show Percentage
- [x] Menu Bar Only
  - [x] Spotlight
  - [x] Siri
- [x] Automatically hide and show the menu bar (Always/On Desktop Only/In Full Screen Only/Never)

### Desktop & Dock
- [x] Dock
  - [x] Size
  - [x] Magnification
    - [x] Enabled
    - [x] Size
  - [x] Position on screen (Left/Bottom/Right)
  - [x] Minimize windows using (Genie/Scale)
  - [x] Double-click a window's title bar to (Fill/Zoom/Minimize/Do Nothing)
  - [x] Minimize windows into application icon
  - [x] Automatically hide and show the Dock
    - [x] Enabled
    - [x] Delay
    - [x] Duration
  - [x] Animate opening applications
  - [x] Show indicators for open applications
  - [x] Show suggested and recent apps in Dock
  - [x] Persistent apps
  - [x] Persistent others
- [x] Desktop & Stage Manager
  - [x] Show items
    - [x] On Desktop
    - [x] In Stage Manager
  - [x] Click wallpaper to reveal desktop (Always/Only in Stage Manager)
  - [x] Stage Manager
  - [x] Show recent apps in Stage Manager
  - [x] Show windows from an application (All at once/One at a time)
- [x] Widgets
  - [x] Show Widgets
    - [x] On Desktop
    - [x] In Stage Manager
  - [x] Widget Style (Automatic/Monochrome/Full-color)
  - [x] Use iPhone Widgets
- [ ] Default web browser
- [x] Windows
  - [x] Prefer tabs when opening documents (Never/Always/In Full Screen)
  - [x] Ask to keep changes when closing documents
  - [x] Close windows when quitting an application
  - [x] Drag windows to screen edges to tile
  - [x] Drag windows to menu bar to fill screen
  - [x] Hold Option key while dragging windows to tile
  - [x] Tiled windows have margin
- [x] Mission Control
  - [x] Automatically rearrange Spaces based on most recent use
  - [x] When switching to an application, switch to a Space with open windows for the application
  - [x] Group windows by application
  - [x] Displays have separate Spaces
  - [x] Drag windows to top of screen to enter Mission Control
- [ ] Shortcuts
- [x] Hot Corners
  - [x] Top Left
  - [x] Top Right
  - [x] Bottom Left
  - [x] Bottom Right

### Spotlight
- [x] Search Results
  - [x] Applications
  - [x] Calculator
  - [x] Contacts
  - [x] Conversion
  - [x] Definition
  - [x] Developer
  - [x] Documents
  - [x] Events & Reminders
  - [x] Folders
  - [x] Fonts
  - [x] Images
  - [x] Mail & Messages
  - [x] Movies
  - [x] Music
  - [x] Other
  - [x] PDF Documents
  - [x] Presentations
  - [x] Siri Suggestions
  - [x] Spreadsheets
  - [x] System Settings
  - [x] Tips
  - [x] Websites
- [x] Help Apple improve Search

### Notifications
- [x] Notification Center
  - [x] Show Previews (Always/When Unlocked/Never)
  - [x] Summarize Notifications

### Sound
- [x] Sound Effects
  - [x] Alert sound (Boop/Breeze/Bubble/Crystal/Funky/Heroine/Jump/Mezzo/Pebble/Pluck/Pong/Sonar/Sonumi/Submerge)
  - [x] Alert volume
  - [ ] Play sound on startup
  - [x] Play user interface sound effects
  - [x] Play feedback when volume is changed

### Focus
- [x] Share across devices

### Keyboard
- [x] Key repeat rate
- [x] Key repeat delay
- [x] Adjust keyboard brightness in low light
- [x] Keyboard brightness
- [x] Turn keyboard backlight off after inactivity
- [x] Press Globe key to (Change Input Source/Show Emoji & Symbols/Start Dictation/Do Nothing)
- [x] Keyboard navigation
- [x] Keyboard Shortcuts
  - [x] Function Keys
    - [x] Use F1, F2, etc. keys as standard function keys
- [x] Dictation
  - [x] Enabled
  - [ ] Shortcut
  - [ ] Auto punctuation
- [ ] Text Input
  - [ ] Show in menubar

### Trackpad
- [x] Tracking speed
- [x] Click (Light/Medium/Firm)
- [x] Force Click and haptic feedback
- [ ] Look up & data detectors
- [ ] Secondary click
- [x] Tap to click

## Applications

### Finder
- [-] Settings
  - [-] General
    - [x] Show these items on the desktop:
      - [x] Hard disks
      - [x] External disks
      - [x] CDs, DVDs, and iPods
      - [x] Connected servers
    - [ ] New Finder windows show:
    - [ ] Sync Desktop & Documents folders
    - [x] Open folders in tabs instead of new windows
  - [ ] Tags
  - [-] Sidebar
    - [ ] Recents
    - [ ] AirDrop
    - [ ] Applications
    - [ ] Desktop
    - [ ] Documents
    - [ ] Downloads
    - [ ] Movies
    - [ ] Music
    - [ ] Pictures
    - [ ] {user}
    - [ ] iCloud Drive
    - [ ] Shared
    - [ ] {host}
    - [ ] Hard disks
    - [ ] External disks
    - [ ] CDs, DVDs, and iOS Devices
    - [ ] Cloud Storage
    - [ ] Bonjour computers
    - [ ] Connected servers
    - [x] Recent Tags
  - [x] Advanced
    - [x] Show all filename extensions
    - [x] Show warning before changing an extension
    - [x] Show warning before removing from iCloud Drive
    - [x] Show warning before emptying the Trash
    - [x] Remove items from the Trash after 30 days
    - [x] Keep folders on top
      - [x] In windows when sorting by name
      - [x] On Desktop
    - [x] When performing a search
- [-] Menu Bar
    - [-] View
      - [ ] ???
      - [x] Show Tab Bar
      - [x] Show Sidebar
      - [x] Show Preview
      - [x] Show Path Bar
      - [x] Show Status Bar
