{ lib }:
{
	checkbox = control: { true = { ${control} = 1; }; false = { ${control} = 0; }; };

	choice = control: choices: lib.genAttrs choices (choice: { ${control} = choice; });

	radio = labels: lib.genAttrs labels (label: { "AXRadioButton:${label}" = 1; });

	values = control: shown: lib.mapAttrs (_: value: { ${control} = value; }) shown;
}
