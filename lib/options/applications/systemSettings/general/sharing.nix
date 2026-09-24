{ lib, settingsLib, ... }:
let
	inherit (settingsLib) setting user system file byHost bool enum storedAs restarts appliesThrough;

	pane = "com.apple.settings.general";
	open = [ "com.apple.systempreferences.general.sharing" ];
	bluetooth = name: byHost (user "com.apple.Bluetooth" name);

	# Services that ask for an administrator in System Settings; nix-darwin applies them as root,
	# the way System Settings does (observed by switching each on and off there).
	launchdOverrides = file "/var/db/com.apple.xpc.launchd/disabled.plist";

	# a system launch daemon that System Settings enables or disables, and loads or unloads
	launchDaemon = label: enabled:
		if enabled then [
			"/bin/launchctl enable system/${label}"
			"/bin/launchctl bootstrap system /System/Library/LaunchDaemons/${label}.plist 2>/dev/null || true"
		] else [
			"/bin/launchctl bootout system/${label} 2>/dev/null || true"
			"/bin/launchctl disable system/${label}"
		];

	service = { ui, storage ? launchdOverrides, apply }: setting {
		inherit storage;
		ui = [ "System Settings" "General" "Sharing" ui ];
		value = bool;
		canUnset = false;
		behaviors = [ (appliesThrough apply) ];
		verify = {
			inherit pane open;
			expect = {
				true = { "AXCheckBox:${ui}Toggle" = 1; };
				false = { "AXCheckBox:${ui}Toggle" = 0; };
			};
		};
	};

	kickstart = "/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart";

	# "Allow access for": "Only these users" is an access group holding Administrators (group 80)
	# unless users are added by hand; "All users" is the group being gone
	accessGroup = { group, id, name }: setting {
		ui = [ "System Settings" "General" "Sharing" "${name} (i)" "Allow access for" ];
		storage = file "/var/db/dslocal/nodes/Default/groups/${group}.plist";
		value = enum { "All users" = "all"; "Only these users" = "only"; };
		canUnset = false;
		behaviors = [
			(appliesThrough (choice:
				if choice == "All users" then "/usr/sbin/dseditgroup -o delete ${group} >/dev/null 2>&1 || true"
				else "/usr/sbin/dseditgroup -o read ${group} >/dev/null 2>&1 || { /usr/sbin/dseditgroup -o create -i ${toString id} -r ${lib.escapeShellArg name} ${group} && /usr/sbin/dseditgroup -o edit -a admin -t group ${group}; }"))
		];
		verify = {
			inherit pane;
			open = open ++ [ "${name}Toggle.infoButton" ];
			expect = {
				"All users" = { "AXPopUpButton:Allow access for" = "All users"; };
				"Only these users" = { "AXPopUpButton:Allow access for" = "Only these users"; };
			};
		};
	};

	assetCache = system "com.apple.AssetCache";
	# the caching service rereads its preferences on request
	reloadsAssetCache = _: plan: plan ++ [ (settingsLib.ops.afterwards "/usr/bin/AssetCacheManagerUtil reloadSettings >/dev/null 2>&1 || true") ];
in
{
	# what System Settings writes; it shows the switch from the running media sharing service,
	# which doesn't pick the key up when it's written, so this isn't verified. Home Sharing needs
	# an Apple Account and isn't covered.
	mediaSharing.shareMediaWithGuests = setting {
		ui = [ "System Settings" "General" "Sharing" "Media Sharing (i)" "Share media with guests" ];
		storage = user "com.apple.amp.mediasharingd" "public-sharing-enabled";
		value = storedAs { true = 1; false = 0; } bool;
		behaviors = [ (restarts "mediasharingd") ];
	};

	bluetoothSharing = {
		enable = setting {
			ui = [ "System Settings" "General" "Sharing" "Bluetooth Sharing" ];
			storage = bluetooth "PrefKeyServicesEnabled";
			value = bool;
			behaviors = [ (restarts "sharingd") ];
			verify = {
				inherit pane open;
				expect = {
					true = { "AXCheckBox:Bluetooth SharingToggle" = 1; };
					false = { "AXCheckBox:Bluetooth SharingToggle" = 0; };
				};
			};
		};

		whenReceivingItems = setting {
			ui = [ "System Settings" "General" "Sharing" "Bluetooth Sharing (i)" "When receiving items" ];
			storage = {
				handling = bluetooth "OBEXFileHandling";
				other = bluetooth "OBEXOtherDataDisposition";
			};
			value = enum {
				"Accept and Save" = { handling = 0; other = 0; };
				"Accept and Open" = { handling = 0; other = 1; };
				"Ask What to Do" = { handling = 1; other = 2; };
				"Never Allow" = { handling = 2; };
			};
			behaviors = [ (restarts "sharingd") ];
			verify = {
				inherit pane;
				open = open ++ [ "Bluetooth SharingToggle.infoButton" ];
				expect = {
					"Accept and Save" = { "AXPopUpButton:When receiving items" = "Accept and Save"; };
					"Ask What to Do" = { "AXPopUpButton:When receiving items" = "Ask What to Do"; };
				};
			};
		};

		whenOtherDevicesBrowse = setting {
			ui = [ "System Settings" "General" "Sharing" "Bluetooth Sharing (i)" "When other devices browse" ];
			storage = bluetooth "OBEXBrowseConnectionHandling";
			value = enum { "Accept and Save" = 0; "Ask What to Do" = 1; "Never Allow" = 2; };
			behaviors = [ (restarts "sharingd") ];
			verify = {
				inherit pane;
				open = open ++ [ "Bluetooth SharingToggle.infoButton" ];
				expect = {
					"Accept and Save" = { "AXPopUpButton:When other devices browse" = "Accept and Save"; };
					"Never Allow" = { "AXPopUpButton:When other devices browse" = "Never Allow"; };
				};
			};
		};
	};

	fileSharing = service {
		ui = "File Sharing";
		apply = launchDaemon "com.apple.smbd";
	};

	screenSharing = service {
		ui = "Screen Sharing";
		apply = launchDaemon "com.apple.screensharing";
	};

	remoteApplicationScripting = service {
		ui = "Remote Application Scripting";
		apply = launchDaemon "com.apple.AEServer";
	};

	printerSharing = service {
		ui = "Printer Sharing";
		storage = file "/etc/cups/cupsd.conf";
		apply = enabled: "/usr/sbin/cupsctl ${if enabled then "--share-printers" else "--no-share-printers"}";
	};

	contentCaching = service {
		ui = "Content Caching";
		storage = system "com.apple.AssetCache" "Activated";
		# the running cache keeps reporting itself active until it's restarted
		apply = enabled: "/usr/bin/AssetCacheManagerUtil ${if enabled then "activate" else "deactivate"} >/dev/null 2>&1 || true; /usr/bin/killall AssetCache 2>/dev/null || true";
	};

	# on: the Remote Management agent for all users with all privileges, as System Settings' OK
	# does by default; it also enables Screen Sharing
	remoteManagement = service {
		ui = "Remote Management";
		storage = system "com.apple.RemoteManagement" "allowInsecureDH";
		apply = enabled:
			if enabled then "${kickstart} -activate -configure -access -on -privs -all -allowAccessFor -allUsers -restart -agent >/dev/null"
			else "${kickstart} -deactivate -configure -access -off >/dev/null";
	};

	screenSharingOptions.allowAccessFor = accessGroup {
		group = "com.apple.access_screensharing";
		id = 398;
		name = "Screen Sharing";
	};

	remoteApplicationScriptingOptions.allowAccessFor = accessGroup {
		group = "com.apple.access_remote_ae";
		id = 400;
		name = "Remote Application Scripting";
	};

	remoteManagementOptions.allowAccessFor = setting {
		ui = [ "System Settings" "General" "Sharing" "Remote Management (i)" "Allow access for" ];
		storage = system "com.apple.RemoteManagement" "ARD_AllLocalUsers";
		value = enum { "All users" = true; "Only these users" = false; };
		verify = {
			inherit pane;
			open = open ++ [ "Remote ManagementToggle.infoButton" ];
			expect = {
				"All users" = { "AXPopUpButton:Allow access for" = "All users"; };
				"Only these users" = { "AXPopUpButton:Allow access for" = "Only these users"; };
			};
		};
	};

	contentCachingOptions = {
		cacheContent = setting {
			ui = [ "System Settings" "General" "Sharing" "Content Caching (i)" "Cache" ];
			storage = {
				personal = assetCache "AllowPersonalCaching";
				shared = assetCache "AllowSharedCaching";
			};
			value = enum {
				"All Content" = { personal = true; shared = true; };
				"Only Shared Content" = { personal = false; shared = true; };
				"Only iCloud Content" = { personal = true; shared = false; };
			};
			behaviors = [ reloadsAssetCache ];
		};

		shareInternetConnection = setting {
			ui = [ "System Settings" "General" "Sharing" "Content Caching (i)" "Internet Connection" ];
			storage = assetCache "AllowTetheredCaching";
			value = bool;
			behaviors = [ reloadsAssetCache ];
			verify = {
				inherit pane;
				open = open ++ [ "Content CachingToggle.infoButton" ];
				expect = {
					true = { "AXCheckBox:Internet Connection" = 1; };
					false = { "AXCheckBox:Internet Connection" = 0; };
				};
			};
		};
	};

	# shared folders by path, each with the name it's shared under; folders shared now but not
	# listed stop being shared. Per-user access isn't covered.
	fileSharingOptions.sharedFolders = setting {
		ui = [ "System Settings" "General" "Sharing" "File Sharing (i)" "Shared Folders" ];
		description = ''
			Folders to share, by path, with the name they're shared under, e.g.
			{ "/Users/me/Public" = "Me’s Public Folder"; }. Folders shared now but not listed stop
			being shared.
		'';
		storage = file "/var/db/dslocal/nodes/Default/sharepoints";
		value = {
			kind = "sharedFolders";
			type = lib.types.attrsOf lib.types.str;
			choices = [];
			examples = [ { "/Users/me/Public" = "Public"; } ];
			encode = _: folders: [];
			fromName = builtins.fromJSON;
			read = { sharedFolders = true; };
		};
		canUnset = false;
		behaviors = [
			(appliesThrough (folders:
				let
					q = lib.escapeShellArg;
				in
				[
					# stop sharing what isn't listed
					''/usr/sbin/sharing -l | /usr/bin/sed -n 's/^path:[[:space:]]*//p' | while IFS= read -r path; do case "$path" in ${if folders == {} then "''" else lib.concatMapStringsSep "|" q (lib.attrNames folders)}) ;; *) /usr/sbin/sharing -r "$(/usr/sbin/sharing -l | /usr/bin/awk -v p="$path" '/^name:/{sub(/^name:[[:space:]]*/,"");n=$0} /^path:/{sub(/^path:[[:space:]]*/,""); if($0==p) print n}')" ;; esac; done''
				]
				++ lib.mapAttrsToList (path: name:
					"/usr/sbin/sharing -l | /usr/bin/grep -qxF ${q "path:		${path}"} || /usr/sbin/sharing -a ${q path} -S ${q name} -n ${q name}"
				) folders))
		];
	};
}
