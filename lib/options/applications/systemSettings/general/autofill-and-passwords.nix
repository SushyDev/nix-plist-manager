{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user bool storedAs;

	pane = "com.apple.settings.general";
	open = [ "com.apple.systempreferences.general.passwords" ];
in
{
	autoFillPasswordsAndPasskeys = setting {
		ui = [ "System Settings" "General" "AutoFill & Passwords" "AutoFill Passwords and Passkeys" ];
		storage = user "com.apple.Safari" "AutoFillPasswords";
		value = bool;
		verify = {
			inherit pane open;
			expect = {
				true = { "AXCheckBox:AutoFillToggle + AutoFill Passwords and Passkeys" = 1; };
				false = { "AXCheckBox:AutoFillToggle + AutoFill Passwords and Passkeys" = 0; };
			};
		};
	};

	autoFillFromPasswords = setting {
		ui = [ "System Settings" "General" "AutoFill & Passwords" "AutoFill from" "Passwords" ];
		storage = user "com.apple.Safari" "AutoFillFromiCloudKeychain";
		value = bool;
		verify = {
			inherit pane open;
			expect = {
				true = { "AXCheckBox:AutoFillFromPasswordsToggle" = 1; };
				false = { "AXCheckBox:AutoFillFromPasswordsToggle" = 0; };
			};
		};
	};

	# System Settings shows this switch from elsewhere, so it can't be verified.
	deleteVerificationCodesAfterUse = setting {
		ui = [ "System Settings" "General" "AutoFill & Passwords" "Verification Codes" "Delete After Use" ];
		storage = {
			messages = user "com.apple.MobileSMS" "DeleteVerificationCodes";
			mail = user "com.apple.onetimepasscodes" "DeleteVerificationCodes";
		};
		value = storedAs {
			true = { messages = true; mail = true; };
			false = { messages = false; mail = false; };
		} bool;
	};
}
