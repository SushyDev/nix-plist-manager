{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user bool inverted enum;

	pane = "com.apple.settings.desktopAndDock";

	showWidgets = { ui, key, control }: setting {
		inherit ui;
		storage = user "com.apple.WindowManager" key;
		value = inverted bool;
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
	showWidgets = {
		onDesktop = showWidgets {
			ui = [ "System Settings" "Desktop & Dock" "Widgets" "Show Widgets" "On Desktop" ];
			key = "StandardHideWidgets";
			control = "show-desktop-widgets";
		};
		inStageManager = showWidgets {
			ui = [ "System Settings" "Desktop & Dock" "Widgets" "Show Widgets" "In Stage Manager" ];
			key = "StageManagerHideWidgets";
			control = "show-stage-manager-widgets";
		};
	};

	dimWidgetsOnDesktop = setting {
		ui = [ "System Settings" "Desktop & Dock" "Widgets" "Dim widgets on desktop" ];
		storage = user "com.apple.widgets" "widgetAppearance";
		value = enum { Always = 0; Never = 1; Automatically = 2; };
		verify = {
			inherit pane;
			expect = {
				Always = { widget-style = "Always"; };
				Never = { widget-style = "Never"; };
				Automatically = { widget-style = "Automatically"; };
			};
		};
	};

}
