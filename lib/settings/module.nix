{ lib, render, isSetting }:
let
	settingsIn = tree:
		let
			walk = prefix: node: lib.concatLists (lib.mapAttrsToList (name: value:
				if isSetting value then [ { path = prefix ++ [ name ]; entry = value; } ]
				else if lib.isAttrs value then walk (prefix ++ [ name ]) value
				else []
			) node);
		in
		walk [] tree;

	inScope = scope: entry: scope == null || entry.scope == scope;

	optionTree = { tree, scope }:
		let
			walk = node: lib.filterAttrs (_: value: value != {}) (lib.mapAttrs (_: value:
				if isSetting value then (if inScope scope value then value.option else {})
				else if lib.isAttrs value then walk value
				else {}
			) node);
		in
		walk tree;

	build = { tree, values, scope, ignoreWarnings ? [] }:
		let
			get = path: lib.attrByPath path null values;
			getDotted = path: get (lib.splitString "." path);

			managed = lib.filter (leaf: inScope scope leaf.entry && get leaf.path != null) (settingsIn tree);

			planFor = path: value:
				let
					other = lib.attrByPath (lib.splitString "." path) null tree;
				in
				if isSetting other then other.plan value else throw "${path} isn't a setting";

			results = lib.concatMap (leaf:
				let
					value = get leaf.path;
					context = { inherit value planFor; path = lib.concatStringsSep "." leaf.path; get = getDotted; };
				in
				lib.optionals (value != "unset") (lib.concatMap (relation: relation context) leaf.entry.relations)
			) managed;

			ofKind = kind: lib.filter (result: result.kind == kind) results;
			ignored = result: lib.elem result.id ignoreWarnings || lib.elem (lib.head (lib.splitString " -> " result.id)) ignoreWarnings;

			plan = lib.concatMap (leaf: leaf.entry.plan (get leaf.path)) managed ++ lib.concatMap (result: result.plan or []) results;
		in
		{
			inherit plan;
			script = render.script plan;
			assertions = map (result: { assertion = false; message = "nix-plist-manager: ${result.message}"; }) (ofKind "assertion");
			warnings = map (result: "nix-plist-manager: ${result.message} (silence with ignoreWarnings = [ \"${result.id}\" ])")
				(lib.filter (result: !(ignored result)) (ofKind "warning"));
		};

	standalone = { tree, values, ignoreWarnings ? [] }:
		let
			evaluated = lib.evalModules {
				modules = [
					{ options.settings = optionTree { inherit tree; scope = null; }; }
					{ config.settings = values; }
				];
			};
			buildScope = scope: build { inherit tree scope ignoreWarnings; values = evaluated.config.settings; };
		in
		{
			user = buildScope "user";
			system = buildScope "system";
		};
in
{
	inherit settingsIn optionTree build standalone;
}
