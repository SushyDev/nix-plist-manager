{ lib }:
rec {
	mkKey = { domain, name, scope ? "user", byHost ? false, type ? null }: {
		_type = "storageKey";
		inherit domain name scope byHost type;
	};

	isKey = value: lib.isAttrs value && value._type or null == "storageKey";

	user = domain: name: mkKey { inherit domain name; };

	domain = name: mkKey { domain = name; name = null; };

	global = name: user "NSGlobalDomain" name;

	system = domain: name: mkKey { inherit domain name; scope = "system"; };

	file = path: mkKey { domain = path; name = null; scope = "system"; };

	byHost = key: key // { byHost = true; };

	stored = type: key: key // { inherit type; };
}
