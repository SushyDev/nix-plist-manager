{ lib, settingsLib, ... }:
# Finder reads its settings at launch, so it's restarted after they're written. New Finder
# windows show, the tags and the sidebar's items aren't covered.
let
	inherit (settingsLib) setting user global bool storedAs enum restarts;

	finder = user "com.apple.finder";

	switch = { ui, storage, value ? bool }: setting {
		inherit storage value;
		ui = [ "Finder" ] ++ ui;
		behaviors = [ (restarts "Finder") ];
	};

	settings = page: ui: storage: switch { ui = [ "Settings…" page ] ++ ui; inherit storage; };
in
{
	settings = {
		general = {
			showTheseItemsOnTheDesktop = let
				desktop = ui: settings "General" [ "Show these items on the desktop" ui ];
			in {
				hardDisks = desktop "Hard disks" (finder "ShowHardDrivesOnDesktop");
				externalDisks = desktop "External disks" (finder "ShowExternalHardDrivesOnDesktop");
				cdsDvdsAndiPods = desktop "CDs, DVDs, and iPods" (finder "ShowRemovableMediaOnDesktop");
				connectedServers = desktop "Connected servers" (finder "ShowMountedServersOnDesktop");
			};

			openFoldersInTabsInsteadOfNewWindows = settings "General" [ "Open folders in tabs instead of new windows" ] (finder "FinderSpawnTab");
		};

		sidebar.recentTags = settings "Sidebar" [ "Recent Tags" ] (finder "ShowRecentTags");

		advanced = {
			showAllFilenameExtensions = settings "Advanced" [ "Show all filename extensions" ] (global "AppleShowAllExtensions");
			showWarningBeforeChangingAnExtension = settings "Advanced" [ "Show warning before changing an extension" ] (finder "FXEnableExtensionChangeWarning");

			# iCloud Drive keeps it, as the warning being suppressed
			showWarningBeforeRemovingFromiCloudDrive = switch {
				ui = [ "Settings…" "Advanced" "Show warning before removing from iCloud Drive" ];
				storage = user "com.apple.bird" "com.apple.clouddocs.unshared.moveOut.suppress";
				value = storedAs { true = 0; false = 1; } bool;
			};

			showWarningBeforeEmptyingTheTrash = settings "Advanced" [ "Show warning before emptying the Trash" ] (finder "WarnOnEmptyTrash");
			removeItemsFromTheTrashAfter30Days = settings "Advanced" [ "Remove items from the Trash after 30 days" ] (finder "FXRemoveOldTrashItems");

			keepFoldersOnTop = {
				inWindowsWhenSortingByName = settings "Advanced" [ "Keep folders on top" "In windows when sorting by name" ] (finder "_FXSortFoldersFirst");
				onDesktop = settings "Advanced" [ "Keep folders on top" "On Desktop" ] (finder "_FXSortFoldersFirstOnDesktop");
			};

			whenPerformingASearch = setting {
				ui = [ "Finder" "Settings…" "Advanced" "When performing a search" ];
				storage = finder "FXDefaultSearchScope";
				value = enum {
					"Search This Mac" = "SCev";
					"Search the Current Folder" = "SCcf";
					"Use the Previous Search Scope" = "SCsp";
				};
				behaviors = [ (restarts "Finder") ];
			};
		};
	};

	menuBar.view = {
		showTabBar = switch {
			ui = [ "Menu Bar" "View" "Show Tab Bar" ];
			storage = finder "NSWindowTabbingShoudShowTabBarKey-com.apple.finder.TBrowserWindow";
		};
		showPathBar = switch { ui = [ "Menu Bar" "View" "Show Path Bar" ]; storage = finder "ShowPathbar"; };
		showStatusBar = switch { ui = [ "Menu Bar" "View" "Show Status Bar" ]; storage = finder "ShowStatusBar"; };
		showSidebar = switch { ui = [ "Menu Bar" "View" "Show Sidebar" ]; storage = finder "ShowSidebar"; };
	};
}
