{ lib }:
# Where a setting keeps its value. Check this against what System Settings writes
# (`nix run .#verify -- observe …`), not against older options: a key in the wrong domain or
# host scope still reads back, but overrides or ignores what is picked in System Settings.
rec {
	mkKey = { domain, name, scope ? "user", byHost ? false, type ? null }: {
		_type = "storageKey";
		inherit domain name scope byHost type;
	};

	isKey = value: lib.isAttrs value && value._type or null == "storageKey";

	# ~/Library/Preferences/<domain>.plist, applied by home-manager. The domain may also be the
	# path of a plist without its extension, "~/Library/Group Containers/…/<domain>", for
	# preferences kept in an app group.
	user = domain: name: mkKey { inherit domain name; };

	# a whole domain, for settings captured as a snapshot (codecs.nix)
	domain = name: mkKey { domain = name; name = null; };

	# NSGlobalDomain (~/Library/Preferences/.GlobalPreferences.plist)
	global = name: user "NSGlobalDomain" name;

	# /Library/Preferences/<domain>.plist, applied by nix-darwin as root
	system = domain: name: mkKey { inherit domain name; scope = "system"; };

	# a file that isn't a plist, e.g. /etc/localtime; only for settings applied through a
	# command (behaviors.appliesThrough), so the docs and verify show where they end up
	file = path: mkKey { domain = path; name = null; scope = "system"; };

	# the current-host variant of a key (~/Library/Preferences/ByHost/<domain>.<UUID>.plist)
	byHost = key: key // { byHost = true; };

	# force the plist type instead of inferring it from the Nix value, e.g. floats the UI
	# writes for whole numbers
	stored = type: key: key // { inherit type; };
}
