# Apply settings without a home-manager or nix-darwin configuration, for testing.
#
#   nix run .#apply -- set <option path> <nix value> [--dry-run]
#   nix run .#apply -- config <file.nix> [--dry-run]
#
#   nix run .#apply -- set applications.systemSettings.appearance.accentColor '"Graphite"'
#   nix run .#apply -- set applications.systemSettings.desktopAndDock.dock.size 48 --dry-run
#
# The file holds the same attrset as programs.nix-plist-manager.options:
#   { applications.systemSettings.appearance.accentColor = "Graphite"; }
#
# Values are type-checked and relations evaluated as in a system configuration: failed
# assertions stop here, warnings are printed. User settings run as you, system settings
# (nix-darwin's) through sudo.
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

result=$(nix eval --json --impure "path:$root#lib.standalone" --apply "f: f $values")

report() {
	printf '%s' "$result" | /usr/bin/python3 -c '
import json, sys
result = json.load(sys.stdin)
failed = [a for scope in result.values() for a in scope["assertions"]]
for scope in result.values():
	for warning in scope["warnings"]:
		print("warning: " + warning, file=sys.stderr)
for assertion in failed:
	print("error: " + assertion, file=sys.stderr)
sys.exit(1 if failed else 0)
'
}
report

user=$(printf '%s' "$result" | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)["user"]["script"])')
system=$(printf '%s' "$result" | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)["system"]["script"])')

if $dry_run; then
	[ -n "$user" ] && printf '# user\n%s\n' "$user"
	[ -n "$system" ] && printf '# system (sudo)\n%s\n' "$system"
	exit 0
fi

[ -n "$user" ] && /bin/bash -c "$user"
[ -n "$system" ] && sudo /bin/bash -c "$system"
exit 0
