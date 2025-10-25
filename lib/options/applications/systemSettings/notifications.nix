{ lib, commandsLib, pathLib, typesLib, configLib, abstractionsLib }:
let
	appleNCPrefs = pathLib.generatePath true false "com.apple.ncprefs";
in
{
	notificationCenter = {
		showPreviews = abstractionsLib.mkBasicMappingOption {
			path = [ "System Settings" "Notification" "Show Previews" ];
			default = null;
			perUser = true;
			mapping = 
				let
					optionName = "content_visibility";
				in
				{
					"unset" = {
						command = commandsLib.defaults.delete appleNCPrefs optionName;
					};
					"Always" = {
						command = commandsLib.defaults.write appleNCPrefs optionName "int" "3";
					};
					"When Unlocked" = {
						command = commandsLib.defaults.write appleNCPrefs optionName "int" "2";
					};
					"Never" = {
						command = commandsLib.defaults.write appleNCPrefs optionName "int" "1";
					};
				};
		};
		summarizeNotifications = 
			let
				optionName = "summarize_previews";
			in
			abstractionsLib.mkBasicBoolOption {
				path = [ "System Settings" "Notification" "Summarize Notifications" ];
				default = null;
				perUser = true;
				unsetCommand = commandsLib.defaults.delete appleNCPrefs optionName;
				trueCommand = commandsLib.defaults.write appleNCPrefs  optionName "bool" "true";
				falseCommand = commandsLib.defaults.write appleNCPrefs optionName "bool" "false";
			};
	};
}

