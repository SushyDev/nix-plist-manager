#!/usr/bin/env python3
"""
plist-watcher — watch macOS preference files for changes and log diffs.

Usage:
    python3 plist-watcher.py [options]

Options:
    --system              Also watch /Library/Preferences (requires sudo)
    --filter <pattern>    Only show domains matching this substring or glob
                          Can be specified multiple times.
                          Example: --filter com.apple.finder --filter NSGlobal
    --output <file>       Tee output to a file in addition to stdout
    --no-color            Disable ANSI colour output

Run with nix:
    nix shell nixpkgs#fswatch --command python3 tools/plist-watcher.py

    # with sudo for system prefs:
    nix shell nixpkgs#fswatch --command sudo python3 tools/plist-watcher.py --system
"""

from __future__ import annotations

import argparse
import fnmatch
import os
import plistlib
import queue
import re
import subprocess
import sys
import threading
import time
from datetime import datetime
from pathlib import Path


# ---------------------------------------------------------------------------
# ANSI colours
# ---------------------------------------------------------------------------

class C:
    RESET   = "\033[0m"
    BOLD    = "\033[1m"
    DIM     = "\033[2m"
    RED     = "\033[31m"
    GREEN   = "\033[32m"
    YELLOW  = "\033[33m"
    CYAN    = "\033[36m"
    MAGENTA = "\033[35m"

def strip_ansi(s: str) -> str:
    return re.sub(r"\033\[[0-9;]*m", "", s)


# ---------------------------------------------------------------------------
# Plist reading helpers
# ---------------------------------------------------------------------------

def read_plist_file(path: Path) -> dict | None:
    """Read a plist file using plutil -convert xml1 piped through plistlib."""
    try:
        result = subprocess.run(
            ["plutil", "-convert", "xml1", "-o", "-", str(path)],
            capture_output=True,
            timeout=5,
        )
        if result.returncode != 0:
            return None
        return plistlib.loads(result.stdout)
    except Exception:
        return None


def plist_path_to_domain(path: Path) -> str:
    """Convert a plist file path to a defaults domain name."""
    name = path.stem
    # Strip ByHost UUID suffix (e.g. com.apple.dock.ABCD1234-...-XXXX)
    name = re.sub(r"\.[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$", "", name, flags=re.IGNORECASE)
    return name


def is_byhost(path: Path) -> bool:
    return "ByHost" in path.parts


def fmt_domain(path: Path) -> str:
    return plist_path_to_domain(path)


def fmt_path_label(path: Path) -> str:
    """Human-readable storage location for a plist path."""
    p = str(path)
    home = str(Path.home())

    # Normalise to a tilde path for display
    display = p.replace(home, "~")

    # Strip the .plist filename — show only the directory
    directory = str(path.parent).replace(home, "~")

    if "/ByHost/" in p:
        scope = "ByHost (per-machine, user)"
    elif p.startswith("/Library/"):
        scope = "system-wide"
    elif "/Library/Preferences" in p:
        scope = "user"
    else:
        scope = "unknown"

    return f"{display}  [{scope}]"


# ---------------------------------------------------------------------------
# Value formatting
# ---------------------------------------------------------------------------

def fmt_value(v) -> str:
    if v is None:
        return "null"
    if isinstance(v, bytes):
        if len(v) > 48:
            return f"<data {len(v)} bytes: {v[:24].hex()}…>"
        return f"<data: {v.hex()}>"
    if isinstance(v, (dict, list)):
        s = repr(v)
        return s if len(s) <= 120 else s[:117] + "…"
    return repr(v)


# ---------------------------------------------------------------------------
# Diff
# ---------------------------------------------------------------------------

def diff_dicts(old: dict, new: dict) -> list[tuple[str, str, object, object]]:
    """
    Returns list of (change_type, key, old_val, new_val).
    change_type is one of: 'added', 'deleted', 'changed'
    """
    changes = []
    all_keys = set(old) | set(new)
    for key in sorted(all_keys):
        if key not in old:
            changes.append(("added", key, None, new[key]))
        elif key not in new:
            changes.append(("deleted", key, old[key], None))
        elif old[key] != new[key]:
            changes.append(("changed", key, old[key], new[key]))
    return changes


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

class Logger:
    def __init__(self, output_path: Path | None, use_color: bool):
        self.use_color = use_color
        self.file = None
        if output_path:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            self.file = open(output_path, "a", encoding="utf-8")

    def write(self, line: str):
        print(line)
        if self.file:
            self.file.write(strip_ansi(line) + "\n")
            self.file.flush()

    def close(self):
        if self.file:
            self.file.close()

    def c(self, colour: str, text: str) -> str:
        if self.use_color:
            return f"{colour}{text}{C.RESET}"
        return text

    def log_change(self, path: Path, changes: list):
        ts = datetime.now().strftime("%H:%M:%S")
        domain_str = fmt_domain(path)
        path_str   = fmt_path_label(path)
        header = (
            self.c(C.BOLD + C.CYAN, f"[{ts}]") + " "
            + self.c(C.BOLD, domain_str) + "\n"
            + self.c(C.DIM, f"  path: {path_str}")
        )
        self.write(header)
        for (kind, key, old_val, new_val) in changes:
            key_str = self.c(C.YELLOW, key)
            if kind == "added":
                val_str = self.c(C.GREEN, fmt_value(new_val))
                self.write(f"  {key_str}: {self.c(C.DIM, '[added]')} {val_str}")
            elif kind == "deleted":
                val_str = self.c(C.RED, fmt_value(old_val))
                self.write(f"  {key_str}: {self.c(C.DIM, '[deleted]')} {val_str}")
            else:
                old_str = self.c(C.RED, fmt_value(old_val))
                new_str = self.c(C.GREEN, fmt_value(new_val))
                self.write(f"  {key_str}: {old_str} → {new_str}")
        self.write("")

    def log_info(self, msg: str):
        self.write(self.c(C.DIM, msg))

    def log_error(self, msg: str):
        self.write(self.c(C.RED, f"[error] {msg}"))


# ---------------------------------------------------------------------------
# Filtering
# ---------------------------------------------------------------------------

def domain_matches_filters(path: Path, filters: list[str]) -> bool:
    if not filters:
        return True
    domain = plist_path_to_domain(path).lower()
    for f in filters:
        f_lower = f.lower()
        if fnmatch.fnmatch(domain, f_lower):
            return True
        if f_lower in domain:
            return True
    return False


# ---------------------------------------------------------------------------
# Snapshot management
# ---------------------------------------------------------------------------

class SnapshotStore:
    def __init__(self):
        self._lock = threading.Lock()
        self._store: dict[str, dict] = {}  # path str -> dict

    def get(self, path: Path) -> dict | None:
        with self._lock:
            return self._store.get(str(path))

    def set(self, path: Path, data: dict):
        with self._lock:
            self._store[str(path)] = data

    def delete(self, path: Path):
        with self._lock:
            self._store.pop(str(path), None)


# ---------------------------------------------------------------------------
# Watch dirs builder
# ---------------------------------------------------------------------------

def build_watch_dirs(include_system: bool) -> list[Path]:
    home = Path.home()
    dirs = [
        home / "Library" / "Preferences",
        home / "Library" / "Preferences" / "ByHost",
    ]
    if include_system:
        dirs += [
            Path("/Library/Preferences"),
            Path("/Library/Preferences/ByHost"),
        ]
    return [d for d in dirs if d.exists()]


def snapshot_dir(directory: Path, filters: list[str], store: SnapshotStore, logger: Logger):
    count = 0
    for plist_file in directory.glob("*.plist"):
        if not domain_matches_filters(plist_file, filters):
            continue
        data = read_plist_file(plist_file)
        if data is not None:
            store.set(plist_file, data)
            count += 1
    return count


# ---------------------------------------------------------------------------
# Event processing
# ---------------------------------------------------------------------------

def process_event(path_str: str, store: SnapshotStore, filters: list[str], logger: Logger):
    path = Path(path_str)

    if path.suffix != ".plist":
        return
    if not domain_matches_filters(path, filters):
        return

    new_data = read_plist_file(path)

    if new_data is None:
        # File deleted or unreadable
        if store.get(path) is not None:
            logger.log_info(f"[{datetime.now().strftime('%H:%M:%S')}] {fmt_domain(path)}: plist removed or unreadable")
            store.delete(path)
        return

    old_data = store.get(path)

    if old_data is None:
        # New file we haven't seen before
        if new_data:
            changes = [("added", k, None, v) for k, v in sorted(new_data.items())]
            logger.log_change(path, changes)
        store.set(path, new_data)
        return

    changes = diff_dicts(old_data, new_data)
    if changes:
        logger.log_change(path, changes)
    store.set(path, new_data)


# ---------------------------------------------------------------------------
# fswatch runner
# ---------------------------------------------------------------------------

def run_fswatch(watch_dirs: list[Path], event_queue: queue.Queue):
    """Run fswatch and push changed file paths onto the queue."""
    cmd = [
        "fswatch",
        "--recursive",
        "--event=Created",
        "--event=Updated",
        "--event=Renamed",
        "--event=Removed",
        "--latency=0.3",   # 300ms debounce
        "--format=%p",
    ] + [str(d) for d in watch_dirs]

    try:
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
    except FileNotFoundError:
        print(
            "Error: fswatch not found.\n"
            "Run with:  nix shell nixpkgs#fswatch --command python3 tools/plist-watcher.py",
            file=sys.stderr,
        )
        sys.exit(1)

    def reader():
        for line in proc.stdout:
            line = line.strip()
            if line:
                event_queue.put(line)
        proc.wait()

    t = threading.Thread(target=reader, daemon=True)
    t.start()
    return proc


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Watch macOS plist files for changes and log diffs.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--system",
        action="store_true",
        help="Also watch /Library/Preferences (requires sudo)",
    )
    parser.add_argument(
        "--filter",
        dest="filters",
        action="append",
        default=[],
        metavar="PATTERN",
        help=(
            "Only show domains matching this substring or glob pattern. "
            "Can be specified multiple times. "
            "Examples: --filter com.apple.finder  --filter 'com.apple.*'  --filter NSGlobal"
        ),
    )
    parser.add_argument(
        "--output",
        metavar="FILE",
        help="Tee output to FILE in addition to stdout (ANSI codes stripped from file)",
    )
    parser.add_argument(
        "--no-color",
        action="store_true",
        help="Disable ANSI colour output",
    )
    args = parser.parse_args()

    use_color = not args.no_color and sys.stdout.isatty()
    logger = Logger(Path(args.output) if args.output else None, use_color)
    store = SnapshotStore()
    watch_dirs = build_watch_dirs(args.system)

    # --- Initial snapshot ---
    logger.log_info(f"Snapshotting {len(watch_dirs)} director(ies)...")
    total = 0
    for d in watch_dirs:
        n = snapshot_dir(d, args.filters, store, logger)
        total += n
        logger.log_info(f"  {d}  ({n} domains)")
    logger.log_info(f"Snapshot complete: {total} domains tracked.")
    if args.filters:
        logger.log_info(f"Filter(s): {', '.join(args.filters)}")
    logger.log_info("Watching for changes... (Ctrl+C to stop)\n")

    # --- Start fswatch ---
    event_queue: queue.Queue = queue.Queue()
    proc = run_fswatch(watch_dirs, event_queue)

    # --- Event loop ---
    try:
        while True:
            try:
                path_str = event_queue.get(timeout=1.0)
            except queue.Empty:
                continue

            # Small sleep to let the write fully flush to disk
            time.sleep(0.05)
            process_event(path_str, store, args.filters, logger)

    except KeyboardInterrupt:
        logger.log_info("\nStopped.")
    finally:
        proc.terminate()
        logger.close()


if __name__ == "__main__":
    main()
