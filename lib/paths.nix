{ lib }:
{
	generatePath = perUser: byHost: name:
		let
			base = if perUser then "$HOME/Library/Preferences" else "/Library/Preferences";
			hostPart = if byHost then "/ByHost" else "";
		in
		base + hostPart + "/" + name;
}
