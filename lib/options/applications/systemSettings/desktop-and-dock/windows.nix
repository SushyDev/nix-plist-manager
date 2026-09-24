{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user global bool inverted enum;

	pane = "com.apple.settings.desktopAndDock";

	switch = { ui, storage, control, value ? bool }: setting {
		inherit ui storage value;
		verify = {
			inherit pane;
			operate = [ "click" control ];
			expect = {
				true = { ${control} = 1; };
				false = { ${control} = 0; };
			};
		};
	};
in
{
	preferTabsWhenOpeningDocuments = setting {
		ui = [ "System Settings" "Desktop & Dock" "Windows" "Prefer tabs when opening documents" ];
		storage = global "AppleWindowTabbingMode";
		value = enum { Never = "manual"; Always = "always"; "In Full Screen" = "fullscreen"; };
		verify = {
			inherit pane;
			expect = {
				Never = { prefer-tabs = "Never"; };
				Always = { prefer-tabs = "Always"; };
				"In Full Screen" = { prefer-tabs = "In Full Screen"; };
			};
		};
	};

	askToKeepChangesWhenClosingDocuments = switch {
		ui = [ "System Settings" "Desktop & Dock" "Windows" "Ask to keep changes when closing documents" ];
		storage = global "NSCloseAlwaysConfirmsChanges";
		control = "ask-to-save-changes";
	};

	closeWindowsWhenQuittingAnApplication = switch {
		ui = [ "System Settings" "Desktop & Dock" "Windows" "Close windows when quitting an application" ];
		storage = global "NSQuitAlwaysKeepsWindows";
		value = inverted bool;
		control = "restore-Windows";
	};

	dragWindowsToLeftOrRightEdgeOfScreenToTile = switch {
		ui = [ "System Settings" "Desktop & Dock" "Windows" "Drag windows to left or right edge of screen to tile" ];
		storage = user "com.apple.WindowManager" "EnableTilingByEdgeDrag";
		control = "tile-on-edge-drag";
	};

	dragWindowsToMenuBarToFillScreen = switch {
		ui = [ "System Settings" "Desktop & Dock" "Windows" "Drag windows to menu bar to fill screen" ];
		storage = user "com.apple.WindowManager" "EnableTopTilingByEdgeDrag";
		control = "tile-on-top-edge-drag";
	};

	holdOptionKeyWhileDraggingWindowsToTile = switch {
		ui = [ "System Settings" "Desktop & Dock" "Windows" "Hold ⌥ key while dragging windows to tile" ];
		storage = user "com.apple.WindowManager" "EnableTilingOptionAccelerator";
		control = "tile-option-accelerator";
	};

	tiledWindowsHaveMargins = switch {
		ui = [ "System Settings" "Desktop & Dock" "Windows" "Tiled windows have margins" ];
		storage = user "com.apple.WindowManager" "EnableTiledWindowMargins";
		control = "tile-margins";
	};
}
