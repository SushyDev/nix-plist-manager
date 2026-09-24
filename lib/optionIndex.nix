{ lib }:
let
	settingsLib = import ./settings { inherit lib; };
in
tree: map (leaf: { option = lib.concatStringsSep "." leaf.path; } // settingsLib.describe leaf.entry) (settingsLib.module.settingsIn tree)
