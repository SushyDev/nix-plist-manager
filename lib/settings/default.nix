{ lib }:
let
	ops = import ./ops.nix { inherit lib; };
	storage = import ./storage.nix { inherit lib; };
	shortcuts = import ./shortcuts.nix { inherit lib; };
	codecs = import ./codecs.nix { inherit lib ops storage shortcuts; };
	behaviorsLib = import ./behaviors.nix { inherit lib ops; };
	relations = import ./relations.nix { inherit lib; };
	core = import ./setting.nix { inherit lib ops behaviorsLib; };
	live = import ./live { inherit lib; };
	render = import ./render.nix { inherit lib live; };
	module = import ./module.nix { inherit lib render; inherit (core) isSetting; };
	describe = import ./describe.nix { inherit lib render; };
	shows = import ./shows.nix { inherit lib; };
	read = import ./read.nix { inherit lib module; };
in
storage // codecs // behaviorsLib // relations // core // describe // {
	inherit ops render module live shortcuts shows read;
}
