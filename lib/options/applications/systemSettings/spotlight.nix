{ lib, commandsLib, pathLib, typesLib, configLib, abstractionsLib }:
let
	appleAssistantSupport = pathLib.generatePath true false "com.apple.assistant.support.plist";
	appleSpotlight = pathLib.generatePath true false "com.apple.Spotlight.plist";
in
{
	helpAppleImproveSearch =
		let
			optionName = "Search Queries Data Sharing Status";
		in
		abstractionsLib.mkBasicBoolOption {
			path = [ "System Settings" "Spotlight" "Help Apple improve Spotlight and Suggestions" ];
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete appleAssistantSupport optionName;
			trueCommand = commandsLib.defaults.write appleAssistantSupport optionName "int" "1";
			falseCommand = commandsLib.defaults.write appleAssistantSupport optionName "int" "0";
		};

	resultsFromClipboard =
		let
			optionName = "PasteboardHistoryEnabled";
		in
		abstractionsLib.mkBasicBoolOption {
			path = [ "System Settings" "Spotlight" "Results from Clipboard" ];
			default = null;
			perUser = true;
			unsetCommand = commandsLib.defaults.delete appleSpotlight optionName;
			trueCommand = commandsLib.defaults.write appleSpotlight optionName "bool" "true";
			falseCommand = commandsLib.defaults.write appleSpotlight optionName "bool" "false";
		};

	clipboardHistoryIsAvailableInSpotlight = abstractionsLib.mkBasicMappingOption {
		path = [ "System Settings" "Spotlight" "Clipboard history is available in Spotlight" ];
		default = null;
		perUser = true;
		mapping = 
			let
				optionName = "PasteboardHistoryTimeout";
			in
			{
				"unset" = {
					command = commandsLib.defaults.delete appleSpotlight optionName;
				};
				"30 minutes" = {
					command = commandsLib.defaults.write appleSpotlight optionName "int" "1800";
				};
				"8 hours" = {
					command = commandsLib.defaults.write appleSpotlight optionName "int" "28800";
				};
				"7 days" = {
					command = commandsLib.defaults.write appleSpotlight optionName "int" "604800";
				};
			};
	};
}
