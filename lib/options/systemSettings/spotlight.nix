{ lib, commandsLib, pathLib, typesLib, configLib, abstractionsLib }:
let
	byHostAppleAssistantSupport = pathLib.generatePath true true "com.apple.assistant.support";
in
{
	helpAppleImproveSearch =
		let
			optionName = "Search Queries Data Sharing Status";
		in
		abstractionsLib.mkBasicBoolOption {
			description = "Spotlight > Help Apple improve Spotlight and Suggestions";
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete byHostAppleAssistantSupport optionName;
			trueCommand = commandsLib.defaults.write byHostAppleAssistantSupport optionName "bool" "true";
			falseCommand = commandsLib.defaults.write byHostAppleAssistantSupport optionName "bool" "false";
		};
}
