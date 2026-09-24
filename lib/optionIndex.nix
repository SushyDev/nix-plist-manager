{ lib }:
let
	settingsLib = import ./settings { inherit lib; };

	collect = attrPath: entries:
		lib.concatLists (lib.mapAttrsToList (name: value:
			let
				currentPath = attrPath ++ [ name ];
			in
			if settingsLib.isEntry value then [ ({ option = lib.concatStringsSep "." currentPath; } // settingsLib.describe value) ]
			else if lib.isAttrs value then collect currentPath value
			else []
		) entries);
in
options: collect [] options
