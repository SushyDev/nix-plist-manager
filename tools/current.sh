# Print this Mac's settings as nix-plist-manager options.
#
#   nix run .#current -- [<file.nix>] [--scope user|system] [--against <file.nix>] [--all] [--only <prefix>] [--ui] [--snapshots <dir>] [--verbose]
#   nix run .#capture -- <option> <directory>
#
# With a file, writes it there instead of printing. --scope prints the options for home-manager (user) or
# nix-darwin (system) alone, ready to import. Settings at macOS's default are left out; --all includes them.
# --against prints only what differs from that file, e.g. after changing something in System Settings.
# --ui reads what isn't stored from System Settings (opens it), --verbose lists what couldn't be read.
set -euo pipefail

usage() { sed -n '/^# Print this Mac/,/^set -euo/p' "$0" | grep '^#' | sed 's/^# \{0,1\}//' >&2; exit 2; }

root="${NIX_PLIST_MANAGER_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

nixString() { printf '"%s"' "$(printf '%s' "$1" | sed 's/[\\"$]/\\&/g')"; }
evaluate() { nix eval --impure "path:$root#lib.$1" --apply "f: f { $2 }" "${@:3}"; }
field() { /usr/bin/plutil -extract "$1" raw -o - "$work/result.json" 2>/dev/null; }

if [ "${1:-}" = capture ]; then
	[ $# -eq 3 ] || usage
	mkdir -p "$3"
	directory=$(cd "$3" && pwd)
	script=$(evaluate collect "capture = { option = $(nixString "$2"); directory = $(nixString "$directory"); };" --raw)
	/bin/bash -c "$script" >/dev/null
	case "$directory" in "$PWD"/*) directory="./${directory#"$PWD"/}" ;; esac
	echo "programs.nix-plist-manager.options.$2 = $directory;"
	exit
fi

file="" scope="" against="" only="" all=false ui=false snapshots="" verbose=false
while [ $# -gt 0 ]; do
	case "$1" in
		--scope) scope="$2"; shift ;;
		--against) against="$2"; shift ;;
		--only) only="$2"; shift ;;
		--snapshots) mkdir -p "$2"; snapshots=$(cd "$2" && pwd); shift ;;
		--all) all=true ;;
		--ui) ui=true ;;
		--verbose) verbose=true ;;
		-h|--help|-*) usage ;;
		*) [ -z "$file" ] || usage; file="$1" ;;
	esac
	shift
done
case "$scope" in ""|user|system) ;; *) usage ;; esac

selection="only = $(nixString "$only");${scope:+ scope = \"$scope\";}"
script=$(evaluate collect "$selection${snapshots:+ snapshots = $(nixString "$snapshots");}" --raw)
/bin/bash -c "$script" > "$work/state.json"

arguments="$selection all = $all; build = \"$(sw_vers -buildVersion)\";${against:+ against = import $(nixString "$(cd "$(dirname "$against")" && pwd)/$(basename "$against")"); againstFile = $(nixString "$against");}"
current() { evaluate current "$arguments collected = builtins.fromJSON (builtins.readFile $work/state.json) // $1; uiRead = $ui;" --json > "$work/result.json"; }
current "{}"

options=$(field fromUI)
if $ui && [ -n "$options" ]; then
	# shellcheck disable=SC2086
	NIX_PLIST_MANAGER_ROOT="$root" nix run "path:$root#verify" -- shown $options > "$work/ui.json"
	current "{ ui = builtins.fromJSON (builtins.readFile $work/ui.json); }"
fi

if [ -n "$file" ]; then
	field text > "$file"
	echo "wrote $file: $(field summary)" >&2
else
	field text
	field summary >&2
fi
if $verbose; then
	field nothingStored >&2
fi
