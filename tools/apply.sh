# Apply settings without a home-manager or nix-darwin configuration.
#
#   nix run .#apply -- set <option path> <nix value> [--dry-run]
#   nix run .#apply -- config <file.nix> [--dry-run]
#
#   nix run .#apply -- set applications.systemSettings.appearance.accentColor '"Graphite"'
set -euo pipefail

usage() { sed -n '/^# Apply settings/,/^set -euo/p' "$0" | grep '^#' | sed 's/^# \{0,1\}//' >&2; exit 2; }

root="${NIX_PLIST_MANAGER_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
dry_run=false
args=()
for arg in "$@"; do
	case "$arg" in
		--dry-run) dry_run=true ;;
		-h|--help) usage ;;
		*) args+=("$arg") ;;
	esac
done

case "${args[0]:-}" in
	set)
		[ "${#args[@]}" -eq 3 ] || usage
		values="(let lib = (builtins.getFlake \"path:$root\").inputs.nixpkgs.lib; in lib.setAttrByPath (lib.splitString \".\" \"${args[1]}\") (${args[2]}))"
		;;
	config)
		[ "${#args[@]}" -eq 2 ] || usage
		values="(import $(realpath "${args[1]}"))"
		;;
	*) usage ;;
esac

script=$(nix eval --raw --impure "path:$root#lib.applyScript" --apply "f: f $values")
if $dry_run; then
	printf '%s\n' "$script"
else
	/bin/bash -c "$script"
fi
