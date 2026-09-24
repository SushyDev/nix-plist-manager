{ lib }:
let
	settingsLib = import ./settings { inherit lib; };
	load = file: import file { inherit lib settingsLib; };
in
{
	applications = {
		systemSettings = {
			general = load ./options/applications/systemSettings/general.nix;
			accessibility = load ./options/applications/systemSettings/accessibility.nix;
			appearance = load ./options/applications/systemSettings/appearance.nix;
			appleIntelligenceAndSiri = load ./options/applications/systemSettings/apple-intelligence-and-siri.nix;
			desktopAndDock = load ./options/applications/systemSettings/desktop-and-dock.nix;
			displays = load ./options/applications/systemSettings/displays.nix;
			battery = load ./options/applications/systemSettings/battery.nix;
			menuBar = load ./options/applications/systemSettings/menu-bar.nix;
			spotlight = load ./options/applications/systemSettings/spotlight.nix;
			wallpaper = load ./options/applications/systemSettings/wallpaper.nix;
			notifications = load ./options/applications/systemSettings/notifications.nix;
			sound = load ./options/applications/systemSettings/sound.nix;
			focus = load ./options/applications/systemSettings/focus.nix;
			lockScreen = load ./options/applications/systemSettings/lock-screen.nix;
			keyboard = load ./options/applications/systemSettings/keyboard.nix;
			trackpad = load ./options/applications/systemSettings/trackpad.nix;
			printersAndScanners = load ./options/applications/systemSettings/printers-and-scanners.nix;
			privacyAndSecurity = load ./options/applications/systemSettings/privacy-and-security.nix;
			network = load ./options/applications/systemSettings/network.nix;
			wiFi = load ./options/applications/systemSettings/wi-fi.nix;
		};
		voiceMemos = load ./options/applications/voice-memos.nix;
		journal = load ./options/applications/journal.nix;
		finder = load ./options/applications/finder.nix;
	};
}
