#!/usr/bin/env bash
# =============================================================================
# cleanup.sh — reclaim disk from stale project leftovers
# =============================================================================
#   ./cleanup.sh          dry run — show what WOULD be removed (default)
#   ./cleanup.sh --go     actually remove it
#
# Everything here was identified from capture-latest/review/REVIEW.md by
# last-modified date. Re-check that file before trusting this list again.
# =============================================================================

set -uo pipefail
GO=0; [ "${1:-}" = "--go" ] && GO=1

TOTAL=0
b()  { printf '\n\033[1;36m▸ %s\033[0m\n' "$1"; }
sz() { du -sk "$1" 2>/dev/null | cut -f1; }

drop() { # path, reason
  local p="$1" r="$2"
  [ -e "$p" ] || return 0
  local k; k=$(sz "$p"); TOTAL=$((TOTAL + k))
  printf '  %-42s %8s MB  %s\n' "${p/#$HOME/\~}" "$((k/1024))" "$r"
  [ "$GO" = 1 ] && rm -rf "$p"
}

b "Empty / dead config dirs"
drop "$HOME/.config/amass"                  "empty"
drop "$HOME/.config/Fritzing"               "empty"
drop "$HOME/.config/iterm2"                 "empty — you moved to Ghostty"
drop "$HOME/.config/simple-update-notifier" "npm artifact, 2022"

b "Finished-project leftovers (ICP / blockchain, 2024)"
# azle is the big one — 4.9 GB of Azle SDK cache, untouched since Oct 2024
drop "$HOME/.config/azle"        "Azle SDK cache, last used 2024-10"
drop "$HOME/.config/dfx"         "DFINITY SDK, 2024-11"
drop "$HOME/.config/concordium"  "2024-08"
drop "$HOME/.config/containers"  "2024-10"
drop "$HOME/.config/Autodesk"    "2024-07"

b "Stale package-manager caches"
drop "$HOME/.config/yarn"        "2023-11 — yarn v1 global cache"
[ -d "$HOME/.npm/_cacache" ] && drop "$HOME/.npm/_cacache" "npm cache (rebuilds itself)"

b "Build / tooling caches (all regenerate on demand)"
drop "$HOME/Library/Developer/Xcode/DerivedData"  "Xcode build cache"
drop "$HOME/Library/Developer/Xcode/iOS DeviceSupport" "old device symbols"
drop "$HOME/Library/Developer/CoreSimulator/Caches" "simulator cache"
drop "$HOME/.gradle/caches"                       "Gradle cache"
drop "$HOME/Library/Caches/Homebrew"              "brew downloads"
drop "$HOME/Library/Caches/pnpm"                  "pnpm store"

b "Orphaned launch agents"
# Adobe CC is NOT in /Applications — this agent has nothing to launch
drop "$HOME/Library/LaunchAgents/com.adobe.ccxprocess.plist" "Adobe not installed"

b "nvm — 17 Node versions"
if [ -d "$HOME/.nvm/versions/node" ]; then
  KEEP="v20.19.3 v24.15.0"          # current LTS + current
  for v in "$HOME/.nvm/versions/node"/*; do
    n=$(basename "$v")
    grep -qw "$n" <<<"$KEEP" || drop "$v" "superseded"
  done
  echo "  keeping: $KEEP"
fi

# ---------------------------------------------------------------------------
b "Total"
printf '  \033[1m%s MB\033[0m (%.1f GB)\n' "$((TOTAL/1024))" "$(echo "$TOTAL/1048576" | bc -l)"
if [ "$GO" = 1 ]; then
  echo
  printf '  \033[0;32mremoved.\033[0m free now: %s\n' "$(df -h / | tail -1 | awk '{print $4}')"
else
  echo
  printf '  \033[0;33mdry run — nothing deleted.\033[0m re-run with --go to apply\n'
fi
echo
echo "  Not touched (decide yourself — recent, possibly in use):"
echo "    ~/.config/opencode  ~/.config/raycast  ~/.config/mole"
echo "    ~/.config/flutter   ~/.config/stripe   ~/.config/sanity"
echo "    ~/.config/neonctl   ~/.config/filezilla ~/.config/flameshot"
echo
