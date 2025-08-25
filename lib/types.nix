{ lib }:
let
	floatBetween = min: max: lib.mkOptionType {
		name = "floatBetween ${toString min} and ${toString max}";
		check = value: builtins.typeOf value == "float" && value >= min && value <= max;
	};
in
{
	inherit floatBetween;
}
