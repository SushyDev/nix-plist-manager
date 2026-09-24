{ lib }:
# The settings library. Option files take what they need from here:
#   let inherit (settingsLib) setting global enum restarts; in { … }
let
	ops = import ./ops.nix { inherit lib; };
	storage = import ./storage.nix { inherit lib; };
	codecs = import ./codecs.nix { inherit lib ops storage; };
	behaviorsLib = import ./behaviors.nix { inherit lib ops; };
	relations = import ./relations.nix { inherit lib; };
	core = import ./setting.nix { inherit lib ops behaviorsLib; };
	render = import ./render.nix { inherit lib; };
	module = import ./module.nix { inherit lib ops render; inherit (core) isSetting; };
	describe = import ./describe.nix { inherit lib render; inherit (core) isSetting; };
	live = import ./live.nix { inherit lib; };
in
storage // codecs // behaviorsLib // relations // core // describe // {
	inherit ops render module live;
}
