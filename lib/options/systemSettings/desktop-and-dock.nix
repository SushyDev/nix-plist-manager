{ lib, commandsLib, pathLib, typesLib, configLib, abstractionsLib }:
let
	imports = {
		inherit lib commandsLib pathLib typesLib configLib abstractionsLib;
	};
in
{
	dock = import ./desktop-and-dock/dock.nix imports;
	desktopAndStageManager = import ./desktop-and-dock/desktop-and-stage-manager.nix imports;
	widgets = import ./desktop-and-dock/widgets.nix imports;
	windows = import ./desktop-and-dock/windows.nix imports;
	missionControl = import ./desktop-and-dock/mission-control.nix imports;
	hotCorners = import ./desktop-and-dock/hot-corners.nix imports;
}
