lib: customLib:
let
	# TODO give the description for each result the normal string
	searchResultsOptions = [
		"applications"
		"calculator"
		"contacts"
		"conversion"
		"definition"
		"developer"
		"documents"
		"eventsAndReminders"
		"folders"
		"fonts"
		"images"
		"mailAndMessages"
		"movies"
		"music"
		"other"
		"pdfDocuments"
		"presentations"
		"siriSuggestions"
		"spreadsheets"
		"systemSettings"
		"tips"
		"websites"
	];
in
{
	searchResults = lib.listToAttrs (map (name: {
		name = name;
		value = lib.mkOption {
			description = "Spotlight > Search Results > ${name}";
			type = lib.types.nullOr lib.types.bool;
			default = true;
		};
	}) searchResultsOptions);

	helpAppleImproveSearch = lib.mkOption {
		description = "Spotlight > Help Apple Improve Search";
		type = lib.types.nullOr lib.types.bool;
		apply = value: if builtins.isNull value then null else if value then 1 else 2;
		default = null;
	};
}
