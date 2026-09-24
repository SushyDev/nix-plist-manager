{ lib, settingsLib, ... }:
# Power settings are kept by powerd (/Library/Preferences/com.apple.PowerManagement.*.plist)
# and changed through pmset, as root. Optimized Battery Charging lives in powerd's archived
# charging policy and isn't here.
let
	inherit (settingsLib) setting system bool enum appliesThrough;

	pane = "com.apple.settings.battery";
	powerManagement = source: system "com.apple.PowerManagement" source;

	pmset = source: key: value: "/usr/bin/pmset -${source} ${key} ${toString value}";
	pmsetBool = source: key: enabled: pmset source key (if enabled then 1 else 0);

	energyMode = { ui, source, storage }: setting {
		inherit ui storage;
		value = enum { Automatic = 0; "Low Power" = 1; "High Power" = 2; };
		canUnset = false;
		behaviors = [
			(appliesThrough (mode: pmset source "powermode" { Automatic = 0; "Low Power" = 1; "High Power" = 2; }.${mode}))
		];
		verify = {
			inherit pane;
			expect = {
				Automatic = { "AXPopUpButton:energy_mode + ${lib.last ui}" = "Automatic"; };
				"Low Power" = { "AXPopUpButton:energy_mode + ${lib.last ui}" = "Low Power"; };
				"High Power" = { "AXPopUpButton:energy_mode + ${lib.last ui}" = "High Power"; };
			};
		};
	};

	option = { ui, control, storage, apply }: setting {
		inherit storage;
		ui = [ "System Settings" "Battery" "Options…" ui ];
		value = bool;
		canUnset = false;
		behaviors = [ (appliesThrough apply) ];
		verify = {
			inherit pane;
			open = [ "Options…" ];
			expect = {
				true = { ${control} = 1; };
				false = { ${control} = 0; };
			};
		};
	};
in
{
	energyMode = {
		onBattery = energyMode {
			ui = [ "System Settings" "Battery" "Energy Mode" "On battery" ];
			source = "b";
			storage = powerManagement "Battery Power";
		};
		onPowerAdapter = energyMode {
			ui = [ "System Settings" "Battery" "Energy Mode" "On power adapter" ];
			source = "c";
			storage = powerManagement "AC Power";
		};
	};

	options = {
		slightlyDimTheDisplayOnBattery = option {
			ui = "Slightly dim the display on battery";
			control = "AXCheckBox:Slightly dim the display on battery";
			storage = powerManagement "Battery Power";
			apply = pmsetBool "b" "lessbright";
		};

		preventAutomaticSleepingOnPowerAdapterWhenTheDisplayIsOff = option {
			ui = "Prevent automatic sleeping on power adapter when the display is off";
			control = "AXCheckBox:Prevent automatic sleeping on power adapter when the display is off";
			storage = powerManagement "AC Power";
			# System Settings sets the sleep timer to 0 (never) or back to 1
			apply = prevent: pmset "c" "sleep" (if prevent then 0 else 1);
		};

		wakeForNetworkAccess = setting {
			ui = [ "System Settings" "Battery" "Options…" "Wake for network access" ];
			storage = { battery = powerManagement "Battery Power"; adapter = powerManagement "AC Power"; };
			value = enum { Always = 0; "Only on Power Adapter" = 1; Never = 2; };
			canUnset = false;
			behaviors = [
				(appliesThrough (choice: [
					(pmsetBool "b" "womp" (choice == "Always"))
					(pmsetBool "c" "womp" (choice != "Never"))
				]))
			];
			verify = {
				inherit pane;
				open = [ "Options…" ];
				expect = {
					Always = { "Wake for network access" = "Always"; };
					"Only on Power Adapter" = { "Wake for network access" = "Only on Power Adapter"; };
					Never = { "Wake for network access" = "Never"; };
				};
			};
		};
	};
}
