#!/usr/bin/env bash
#
# dock.sh — set the Dock's contents from macos/dock.txt.
#
#   ./macos/dock.sh          # apply
#   ./macos/dock.sh --dry    # show what would change, touch nothing
#
# Must run AFTER the Brewfile step: it skips apps that are not installed, so
# running it before the apps exist silently produces an empty Dock.
#
# Uses dockutil when present. Falls back to writing the persistent-apps array
# directly — in ONE `defaults write`, not N `-array-add` calls, because each
# add is a separate cfprefsd round-trip and they get dropped under load.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

say()  { printf '\033[0;34m→\033[0m %s\n' "$1"; }
ok()   { printf '\033[0;32m✓\033[0m %s\n' "$1"; }
warn() { printf '\033[0;33m!\033[0m %s\n' "$1"; }

[ "$(uname -s)" = Darwin ] || { echo "macOS only" >&2; exit 1; }

DRY=0
[ "${1:-}" = "--dry" ] && DRY=1
LIST="macos/dock.txt"
[ -f "$LIST" ] || { echo "missing $LIST" >&2; exit 1; }

# ---- read the list, skipping anything not actually installed ----------------
apps=""
missing=0
while IFS= read -r line; do
  case "$line" in ''|\#*) continue ;; esac
  if [ -e "$line" ]; then
    apps="$apps$line
"
  else
    warn "not installed, skipping: $line"
    missing=$((missing + 1))
  fi
done < "$LIST"

count=$(printf '%s' "$apps" | grep -c . || true)
[ "$count" -gt 0 ] || { warn "nothing to add — is the Brewfile step done?"; exit 0; }

if [ "$DRY" -eq 1 ]; then
  say "would set the Dock to $count apps:"
  printf '%s' "$apps" | sed 's/^/    /'
  [ "$missing" -gt 0 ] && warn "$missing listed app(s) not installed"
  exit 0
fi

say "setting Dock ($count apps)"

if command -v dockutil >/dev/null 2>&1; then
  # One invocation: --no-restart on every step but the last, so the Dock
  # restarts once at the end rather than after each change.
  args=(--remove all --no-restart)
  while IFS= read -r app; do
    [ -n "$app" ] || continue
    args+=(--add "$app" --no-restart)
  done <<EOF
$apps
EOF
  unset 'args[${#args[@]}-1]'      # drop the trailing --no-restart
  dockutil "${args[@]}" || { warn "dockutil failed"; exit 1; }
else
  # No dockutil: build the whole array and write it in a single call.
  tiles=()
  while IFS= read -r app; do
    [ -n "$app" ] || continue
    tiles+=("<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>")
  done <<EOF
$apps
EOF
  defaults write com.apple.dock persistent-apps -array "${tiles[@]}"
  killall Dock >/dev/null 2>&1 || true
fi

ok "dock set"
[ "$missing" -gt 0 ] && warn "$missing listed app(s) were not installed"
exit 0
