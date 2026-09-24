{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting system bool enum appliesThrough live;

	pane = "com.apple.settings.battery";
	sections = { b = "Battery Power"; c = "AC Power"; };
	powerManagement = source: system "com.apple.PowerManagement" sections.${source};

	pmset = source: key: value: "/usr/bin/pmset -${source} ${key} ${toString value}";
	pmsetBool = source: key: enabled: pmset source key (if enabled then 1 else 0);
	onOff = { true = 1; false = 0; };

	modes = { Automatic = 0; "Low Power" = 1; "High Power" = 2; };

	energyMode = { ui, source }: setting {
		inherit ui;
		storage = powerManagement source;
		value = enum modes;
		canUnset = false;
		behaviors = [ (appliesThrough (mode: pmset source "powermode" modes.${mode})) ];
		reads = { command = live.pmsetValue sections.${source} "powermode"; values = modes; };
		verify = {
			inherit pane;
			expect = {
				Automatic = { "AXPopUpButton:energy_mode + ${lib.last ui}" = "Automatic"; };
				"Low Power" = { "AXPopUpButton:energy_mode + ${lib.last ui}" = "Low Power"; };
				"High Power" = { "AXPopUpButton:energy_mode + ${lib.last ui}" = "High Power"; };
			};
		};
	};

	option = { ui, control, source, apply, reads }: setting {
		inherit reads;
		ui = [ "System Settings" "Battery" "Options…" ui ];
		storage = powerManagement source;
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
		};
		onPowerAdapter = energyMode {
			ui = [ "System Settings" "Battery" "Energy Mode" "On power adapter" ];
			source = "c";
		};
	};

	options = {
		slightlyDimTheDisplayOnBattery = option {
			ui = "Slightly dim the display on battery";
			control = "AXCheckBox:Slightly dim the display on battery";
			source = "b";
			apply = pmsetBool "b" "lessbright";
			reads = { command = live.pmsetValue sections.b "lessbright"; values = onOff; };
		};

		preventAutomaticSleepingOnPowerAdapterWhenTheDisplayIsOff = option {
			ui = "Prevent automatic sleeping on power adapter when the display is off";
			control = "AXCheckBox:Prevent automatic sleeping on power adapter when the display is off";
			source = "c";
			# System Settings sets the sleep timer to 0 (never) or back to 1.
			apply = prevent: pmset "c" "sleep" (if prevent then 0 else 1);
			reads.command = "${live.pmsetValue sections.c "sleep"} | /usr/bin/awk '{ print ($1 == 0 ? \"true\" : \"false\") }'";
		};

		wakeForNetworkAccess = setting {
			ui = [ "System Settings" "Battery" "Options…" "Wake for network access" ];
			storage = { battery = powerManagement "b"; adapter = powerManagement "c"; };
			value = enum { Always = 0; "Only on Power Adapter" = 1; Never = 2; };
			canUnset = false;
			behaviors = [
				(appliesThrough (choice: [
					(pmsetBool "b" "womp" (choice == "Always"))
					(pmsetBool "c" "womp" (choice != "Never"))
				]))
			];
			reads = {
				command = ''echo "$(${live.pmsetValue sections.b "womp"}) $(${live.pmsetValue sections.c "womp"})"'';
				values = { Always = "1 1"; "Only on Power Adapter" = "0 1"; Never = "0 0"; };
			};
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
