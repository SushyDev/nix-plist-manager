{ lib }:
{
	defaults = {
		delete = path: optionName:
			''/usr/bin/defaults delete ${path} ${optionName}'';
		write = path: optionName: type: value:
			''/usr/bin/defaults write ${path} ${optionName} -${type} "${lib.escapeShellArg value}"'';
	};
	osaScript = script:
		''/usr/bin/osascript -e ${lib.escapeShellArg script}'';

	notifyUtilPost = notification:
		''/usr/bin/notifyutil -p ${lib.escapeShellArg notification}'';
}
