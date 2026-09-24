{ lib, ops }:
rec {
	restarts = process: _: plan: plan ++ [ (ops.restart process) ];

	activatesShortcuts = _: plan: plan ++ [
		(ops.afterwards "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u")
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
