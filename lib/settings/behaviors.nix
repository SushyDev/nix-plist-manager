{ lib, ops }:
# A behavior rewrites a setting's plan: `context: plan: plan`, where context is
# { keys, value } for the value being applied. Settings list the ones they need; `defaults`
# apply to every setting.
rec {
	# restarted once, after every setting has been written
	restarts = process: _: plan: plan ++ [ (ops.restart process) ];

	# keyboard shortcuts (com.apple.symbolichotkeys) take effect without logging out
	activatesShortcuts = _: plan: plan ++ [
		(ops.afterwards "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u")
	];

	# the same for a process that saves its own state when it quits, like the Dock its contents:
	# it's killed without the chance to write over what was just restored
	restartsDiscardingItsState = process: _: plan: plan ++ [ (ops.restartDiscarding process) ];

	# posted once, after every write, so running apps pick the change up
	notifies = names: _: plan: plan ++ map ops.notify (lib.toList names);

	# replace the key writes with commands that apply the value live, for state that is owned
	# by a system service rather than read from the plist. `apply` gets the value and returns
	# shell commands. Storage stays declared so the docs and verify know where the
	# value ends up.
	appliesThrough = apply: context: plan:
		if context.value == "unset" then plan
		else map ops.run (lib.toList (apply context.value));

	# Earlier versions of this module wrote some settings to the current-host (ByHost) copy of
	# their domain. That copy takes precedence, so it would keep overriding what is picked in
	# System Settings; applying a setting clears it for each of its keys.
	clearsByHostCopy = context: plan:
		plan ++ lib.concatMap (key:
			# whole domains and plists addressed by path have no current-host copy
			lib.optional (key.scope == "user" && !key.byHost && key.name != null && !(lib.hasPrefix "~/" key.domain))
				(ops.delete (key // { byHost = true; }))
		) (lib.attrValues context.keys);

	# run after a setting's own behaviors
	defaults = [ clearsByHostCopy ];
}
