nix shell nixpkgs#fswatch --command sudo python3 ./plist-watcher.py \
  --system \
  --output /tmp/plist-changes.log
