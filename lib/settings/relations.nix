{ lib }:
# Relations between settings, checked against the whole configuration. A relation is
# `context: [ result ]`, where context is
#   { path, value, get, planFor }
#   path     this setting's option path
#   value    its configured value (never null or "unset": relations are skipped then)
#   get      option path -> configured value, null when that setting isn't managed
#   planFor  option path -> value -> the plan that setting would apply
# and a result is { kind = "assertion" | "warning"; id; message; plan ? []; }.
#
# When the other setting isn't managed, relations warn instead of failing. Warnings can be
# silenced per setting, or per relation by its id ("<setting> -> <other setting>"), with
# programs.nix-plist-manager.ignoreWarnings.
let
	result = kind: context: other: message: extra: {
		inherit kind message;
		id = "${context.path} -> ${other}";
	} // extra;

	show = value: builtins.toJSON value;

	unmanaged = context: other: reason:
		result "warning" context other
			"${context.path} = ${show context.value}: ${reason}, and ${other} isn't managed here." { };
in
{
	# the setting only has a visible effect when `other` satisfies `condition`
	onlyWhen = other: condition: reason: context:
		let
			otherValue = context.get other;
		in
		if otherValue == null then [ (unmanaged context other reason) ]
		else lib.optional (!(condition otherValue))
			(result "warning" context other
				"${context.path} = ${show context.value} has no effect while ${other} = ${show otherValue}: ${reason}." { });

	# `value` can only be picked when `other` satisfies `condition`
	allowedWhen = value: other: condition: reason: context:
		let
			otherValue = context.get other;
		in
		if context.value != value then []
		else if otherValue == null then [ (unmanaged context other reason) ]
		else lib.optional (!(condition otherValue))
			(result "assertion" context other
				"${context.path} = ${show value} can't be combined with ${other} = ${show otherValue}: ${reason}." { });

	# the setting can't be combined with `other` satisfying `condition`
	conflictsWith = other: condition: reason: context:
		let
			otherValue = context.get other;
		in
		lib.optional (otherValue != null && condition otherValue)
			(result "assertion" context other
				"${context.path} = ${show context.value} can't be combined with ${other} = ${show otherValue}: ${reason}." { });

	# setting this one sets `other` to `otherValue`, the way System Settings does. When `other`
	# is managed it has to agree; when it isn't, its keys are written too, with a warning.
	implies = other: otherValue: reason: context:
		let
			current = context.get other;
		in
		if current == null then [
			(result "warning" context other
				"${context.path} = ${show context.value} also sets ${other} = ${show otherValue}: ${reason}. Set ${other} to make that explicit."
				{ plan = context.planFor other otherValue; })
		]
		else lib.optional (current != otherValue)
			(result "assertion" context other
				"${context.path} = ${show context.value} needs ${other} = ${show otherValue}, not ${show current}: ${reason}." { });
}
