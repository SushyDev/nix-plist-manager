{ lib, customLib, config }:
let
	nix-plist-manager = config.nix-plist-manager;
	users = nix-plist-manager.users;

	orderedItemsMapping = {
		"APPLICATIONS" = nix-plist-manager.systemSettings.spotlight.searchResults.applications;
		"MENU_EXPRESSION" = nix-plist-manager.systemSettings.spotlight.searchResults.calculator;
		"CONTACT" = nix-plist-manager.systemSettings.spotlight.searchResults.contacts;
		"MENU_CONVERSION" = nix-plist-manager.systemSettings.spotlight.searchResults.conversion;
		"MENU_DEFINITION" = nix-plist-manager.systemSettings.spotlight.searchResults.definition;
		"SOURCE" = nix-plist-manager.systemSettings.spotlight.searchResults.developer;
		"DOCUMENTS" = nix-plist-manager.systemSettings.spotlight.searchResults.documents;
		"EVENT_TODO" = nix-plist-manager.systemSettings.spotlight.searchResults.eventsAndReminders;
		"DIRECTORIES" = nix-plist-manager.systemSettings.spotlight.searchResults.folders;
		"FONTS" = nix-plist-manager.systemSettings.spotlight.searchResults.fonts;
		"IMAGES" = nix-plist-manager.systemSettings.spotlight.searchResults.images;
		"MESSAGES" = nix-plist-manager.systemSettings.spotlight.searchResults.mailAndMessages;
		"MOVIES" = nix-plist-manager.systemSettings.spotlight.searchResults.movies;
		"MUSIC" = nix-plist-manager.systemSettings.spotlight.searchResults.music;
		"MENU_OTHER" = nix-plist-manager.systemSettings.spotlight.searchResults.other;
		"PDF" = nix-plist-manager.systemSettings.spotlight.searchResults.pdfDocuments;
		"PRESENTATIONS" = nix-plist-manager.systemSettings.spotlight.searchResults.presentations;
		"MENU_SPOTLIGHT_SUGGESTIONS" = nix-plist-manager.systemSettings.spotlight.searchResults.siriSuggestions;
		"SPREADSHEETS" = nix-plist-manager.systemSettings.spotlight.searchResults.spreadsheets;
		"SYSTEM_PREFS" = nix-plist-manager.systemSettings.spotlight.searchResults.systemSettings;
		"TIPS" = nix-plist-manager.systemSettings.spotlight.searchResults.tips;
		"BOOKMARKS" = nix-plist-manager.systemSettings.spotlight.searchResults.websites;
	};

	orderedItems = lib.mapAttrsToList (name: enabled: {
		name = name;
		enabled = enabled;
	}) orderedItemsMapping;

	spotlightFileCreate = user: "mkdir -p ~${user}/Library/Preferences && plutil -create xml1 ~${user}/Library/Preferences/com.apple.Spotlight.plist";
	spotlightCommand = user: "plutil -replace orderedItems -json '${builtins.toJSON orderedItems}' ~${user}/Library/Preferences/com.apple.Spotlight.plist";
in 
lib.map (user: customLib.runAsUser user (spotlightFileCreate user)) users ++
lib.map (user: customLib.runAsUser user (spotlightCommand user)) users
