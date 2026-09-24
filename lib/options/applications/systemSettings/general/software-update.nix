{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting system bool storedAs;

	pane = "com.apple.settings.general";
	open = [ "com.apple.systempreferences.general.softwareUpdate" "AdvancedView.LabeledContent.infoButton" ];

	switch = { ui, storage, control, value ? bool }: setting {
		inherit storage value;
		ui = [ "System Settings" "General" "Software Update" "Automatic Updates (i)" ui ];
		verify = {
			inherit pane open;
			expect = {
				true = { "AXCheckBox:${control}" = 1; };
				false = { "AXCheckBox:${control}" = 0; };
			};
		};
	};
in
{
	automaticallyDownloadNewUpdatesWhenAvailable = switch {
		ui = "Download new updates when available";
		storage = system "com.apple.SoftwareUpdate" "AutomaticDownload";
		control = "AdvancedOptionsView.DownloadNewUpdatesToggle";
	};

	automaticallyInstallMacOSUpdates = switch {
		ui = "Install macOS updates";
		storage = system "com.apple.SoftwareUpdate" "AutomaticallyInstallMacOSUpdates";
		control = "AdvancedOptionsView.InstallMacOSUpdatesToggle";
	};

	automaticallyInstallSystemDataFilesAndSecurityUpdates = switch {
		ui = "Install system data files and security updates";
		storage = {
			configData = system "com.apple.SoftwareUpdate" "ConfigDataInstall";
			critical = system "com.apple.SoftwareUpdate" "CriticalUpdateInstall";
		};
		value = storedAs {
			true = { configData = true; critical = true; };
			false = { configData = false; critical = false; };
		} bool;
		control = "AdvancedOptionsView.InstallSecurityResponsesToggle";
	};

	automaticallyInstallApplicationUpdatesFromTheAppStore = setting {
		ui = [ "App Store" "Settings" "Automatic Updates" ];
		storage = system "com.apple.commerce" "AutoUpdate";
		value = bool;
	};
}
