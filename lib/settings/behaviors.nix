{ lib, ops }:
rec {
	restarts = process: _: plan: plan ++ [ (ops.restart process) ];

	# Only a logged-in user has a window server to hand shortcuts to; the others read them at login.
	activatesShortcuts = _: plan: plan ++ [
		(ops.afterwards "if /bin/launchctl print gui/$(/usr/bin/id -u) >/dev/null 2>&1; then /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u; fi")
	];

	# A process that saves its state when it quits would otherwise write over what was just restored.
	restartsDiscardingItsState = process: _: plan: plan ++ [ (ops.restartDiscarding process) ];

	notifies = names: _: plan: plan ++ map ops.notify (lib.toList names);

	appliesThrough = apply: context: plan:
		if context.value == "unset" then plan
		else map ops.run (lib.toList (apply context.value));

	# Older versions wrote current-host copies, which override what System Settings picks.
	clearsByHostCopy = context: plan:
		plan ++ lib.concatMap (key:
			lib.optional (key.scope == "user" && !key.byHost && key.name != null && !(lib.hasPrefix "~/" key.domain))
				(ops.delete (key // { byHost = true; }))
		) (lib.attrValues context.keys);

	defaults = [ clearsByHostCopy ];
}
