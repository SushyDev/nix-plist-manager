{ lib }:
{
	commandNullOrBoolOrUnset = mapping: value:
		if builtins.isNull value then mapping."unset".command
		else if value == true then mapping."true".command
		else mapping."false".command;

	commandNullOrValueOrUnset = mapping: value:
		if builtins.isNull value then null
		else if value == "unset" then mapping."unset".command
		else mapping."value".command value;

	commandMapping = mapping: value:
		if builtins.isNull value then null
		else mapping.${value}.command;
}
