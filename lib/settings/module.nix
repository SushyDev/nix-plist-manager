{ lib, ops, render, isSetting }:
# What the home-manager and nix-darwin modules share: collect the plan of every managed
# setting in their scope, evaluate relations, and render one script.
let
	# [ { path = [ … ]; entry = <setting>; } ]
	leaves = tree: prefix:
		lib.concatLists (lib.mapAttrsToList (name: value:
			let
				path = prefix ++ [ name ];
			in
			if isSetting value then [ { inherit path; entry = value; } ]
			else if lib.isAttrs value then leaves value path
			else []
		) tree);

	# scope null: both
	inScope = scope: entry:
		scope == null || entry.scope == scope;
in
{
	# the option declarations for one scope, same shape as `tree`, without empty branches
	optionTree = { tree, scope }:
		let
			walk = node: lib.filterAttrs (_: value: value != {}) (lib.mapAttrs (_: value:
				if isSetting value then (if inScope scope value then value.option else {})
				else if lib.isAttrs value then walk value
				else {}
			) node);
		in
		walk tree;

	# Outside home-manager and nix-darwin (`nix run .#apply`): type-check `values` with the module
	# system, like the modules would, and build both scopes.
	standalone = { tree, values, ignoreWarnings ? [] }:
		let
			self = import ./module.nix { inherit lib ops render isSetting; };
			evaluated = lib.evalModules {
				modules = [
					{ options.settings = self.optionTree { inherit tree; scope = null; }; }
					{ config.settings = values; }
				];
			};
			build = scope: self.build { inherit tree scope ignoreWarnings; values = evaluated.config.settings; };
		in
		{
			user = build "user";
			system = build "system";
		};

	# tree: lib/options.nix; values: the configured option values, same shape; scope: "user" or "system"
	build = { tree, values, scope, ignoreWarnings ? [] }:
		let
			get = path: lib.attrByPath path null values;
			dotted = lib.concatStringsSep ".";

			managed = lib.filter (leaf: inScope scope leaf.entry && get leaf.path != null) (leaves tree []);

			planOf = leaf: leaf.entry.plan (get leaf.path);

			results = lib.concatMap (leaf:
				let
					value = get leaf.path;
				in
				lib.optionals (value != "unset") (lib.concatMap (relation: relation {
					inherit value;
					path = dotted leaf.path;
					get = path: get (lib.splitString "." path);
					planFor = path: v:
						let
							other = lib.attrByPath (lib.splitString "." path) null tree;
						in
						if isSetting other then other.plan v else throw "${path} isn't a setting";
				}) leaf.entry.relations)
			) managed;

			ignored = result: lib.any (pattern: pattern == result.id || pattern == lib.head (lib.splitString " -> " result.id)) ignoreWarnings;

			plan = lib.concatMap planOf managed ++ lib.concatMap (result: result.plan or []) results;
		in
		{
			inherit plan;
			script = render.script plan;
			assertions = map (result: {
				assertion = false;
				message = "nix-plist-manager: ${result.message}";
			}) (lib.filter (result: result.kind == "assertion") results);
			warnings = map (result: "nix-plist-manager: ${result.message} (silence with ignoreWarnings = [ \"${result.id}\" ])")
				(lib.filter (result: result.kind == "warning" && !(ignored result)) results);
		};
}
