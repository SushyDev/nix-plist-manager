{ lib, commandsLib, pathLib, typesLib, configLib, abstractionsLib }:
let
	appleDoNotDisturbd = pathLib.generatePath true false "com.apple.donotdisturbd";
in
{
	shareAcrossDevices = 
		let
			optionName = "disableCloudSync";
		in
		abstractionsLib.mkBasicBoolOption {
			path = [ "System Settings" "Focus" "Share across devices" ];
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete appleDoNotDisturbd optionName;
			trueCommand = commandsLib.defaults.write appleDoNotDisturbd optionName "bool" "false";
			falseCommand = commandsLib.defaults.write appleDoNotDisturbd optionName "bool" "true";
		};
}
