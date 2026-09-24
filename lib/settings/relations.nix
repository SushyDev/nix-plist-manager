{ lib }:
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
	onlyWhen = other: condition: reason: context:
		let
			otherValue = context.get other;
		in
		if otherValue == null then [ (unmanaged context other reason) ]
		else lib.optional (!(condition otherValue))
			(result "warning" context other
				"${context.path} = ${show context.value} has no effect while ${other} = ${show otherValue}: ${reason}." { });

	allowedWhen = value: other: condition: reason: context:
		let
			otherValue = context.get other;
		in
		if context.value != value then []
		else if otherValue == null then [ (unmanaged context other reason) ]
		else lib.optional (!(condition otherValue))
			(result "assertion" context other
				"${context.path} = ${show value} can't be combined with ${other} = ${show otherValue}: ${reason}." { });

	conflictsWith = other: condition: reason: context:
		let
			otherValue = context.get other;
		in
		lib.optional (otherValue != null && condition otherValue)
			(result "assertion" context other
				"${context.path} = ${show context.value} can't be combined with ${other} = ${show otherValue}: ${reason}." { });

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
