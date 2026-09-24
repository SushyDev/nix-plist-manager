{ lib, settingsLib, ... }:
let
	section = file: import file { inherit lib settingsLib; };
in
{
	airDropAndContinuity = section ./general/airdrop-and-continuity.nix;
	autoFillAndPasswords = section ./general/autofill-and-passwords.nix;
	dateAndTime = section ./general/date-and-time.nix;
	languageAndRegion = section ./general/language-and-region.nix;
	sharing = section ./general/sharing.nix;
	softwareUpdate = section ./general/software-update.nix;
}
