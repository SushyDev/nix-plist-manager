{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user enum;
in
{
	defaultPaperSize = setting {
		ui = [ "System Settings" "Printers & Scanners" "Default paper size" ];
		storage = user "org.cups.PrintingPrefs" "DefaultPaperID";
		value = enum {
			"US Letter" = "na-letter";
			"US Legal" = "na-legal";
			A4 = "iso-a4";
			A5 = "iso-a5";
			"JIS B5" = "jis-b5";
			B5 = "iso-b5";
			"Envelope #10" = "na-number-10-envelope";
			"Envelope DL" = "iso-designated";
			Tabloid = "tabloid";
			A3 = "iso-a3";
			"Tabloid Oversize" = "arch-b";
			"ROC 16K" = "ROC 16K";
			"Envelope Choukei 3" = "Envelope Choukei 3";
			"Super B/A3" = "super-b";
		};
		verify = {
			pane = "com.apple.settings.printerAndScanner";
			expect = {
				"US Letter" = { "AXPopUpButton:DefaultPaperSizeOption" = "US Letter"; };
				A3 = { "AXPopUpButton:DefaultPaperSizeOption" = "A3"; };
			};
		};
	};
}
