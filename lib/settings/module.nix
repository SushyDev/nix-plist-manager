{ lib, ops, render, isSetting }:
let
	leaves = tree: prefix:
		lib.concatLists (lib.mapAttrsToList (name: value:
			let
				path = prefix ++ [ name ];
			in
			if isSetting value then [ { inherit path; entry = value; } ]
			else if lib.isAttrs value then leaves value path
			else []
		) tree);

	inScope = scope: entry:
		scope == null || entry.scope == scope;
in
{
	optionTree = { tree, scope }:
		let
			walk = node: lib.filterAttrs (_: value: value != {}) (lib.mapAttrs (_: value:
				if isSetting value then (if inScope scope value then value.option else {})
				else if lib.isAttrs value then walk value
				else {}
			) node);
		in
		walk tree;

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
