{ lib }:
{
	defaults = {
		delete = path: optionName:
			''/usr/bin/defaults delete ${path} ${optionName} 2>/dev/null || true'';
		write = path: optionName: type: value:
			''/usr/bin/defaults write ${path} ${optionName} -${type} "${lib.escapeShellArg value}" 2>/dev/null || true'';
	};

	chainOnSuccess = " && \\\n";

	osaScript = script:
		''/usr/bin/osascript -e ${lib.escapeShellArg script} 2>/dev/null || true'';

	notifyUtilPost = notification:
		''/usr/bin/notifyutil -p ${lib.escapeShellArg notification} 2>/dev/null || true'';

	killall = processName:
		''/usr/bin/killall ${lib.escapeShellArg processName} 2>/dev/null || true'';
}
