#!/usr/bin/env bash
#
# defaults.sh — macOS system preferences.
#
#   ./macos/defaults.sh          # apply
#   ./macos/defaults.sh --dry    # print what would change, touch nothing
#
# Values marked "captured" are read from bbn-mbp on 2026-08-22. The rest come
# from the earlier WIP setup and are sensible defaults, not current state.
#
# Log out for the keyboard and trackpad settings to take effect.

set -uo pipefail

DRY=0
[ "${1:-}" = "--dry" ] && DRY=1

d() {
  if [ "$DRY" -eq 1 ]; then
    printf '  would: defaults %s\n' "$*"
  else
    defaults "$@"
  fi
}
say() { printf '\033[0;34m→\033[0m %s\n' "$1"; }
ok()  { printf '\033[0;32m✓\033[0m %s\n' "$1"; }

[ "$(uname -s)" = Darwin ] || { echo "macOS only" >&2; exit 1; }

# ---- pointer and keyboard (captured from this machine) ----------------------
say "pointer and keyboard"
d write -g com.apple.mouse.scaling -float 1.5
d write -g com.apple.trackpad.scaling -float 0.875
d write -g com.apple.swipescrolldirection -bool false   # natural scrolling OFF
d write -g AppleKeyboardUIMode -int 3                   # tab reaches every control
d write -g InitialKeyRepeat -int 15
d write -g KeyRepeat -int 2
d write -g ApplePressAndHoldEnabled -bool false         # key repeat, not accents
d write com.apple.AppleMultitouchTrackpad Clicking -bool true
d write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
ok "pointer"

# ---- finder -----------------------------------------------------------------
say "finder"
d write com.apple.finder AppleShowAllFiles -bool true
d write -g AppleShowAllExtensions -bool true
d write com.apple.finder ShowPathbar -bool true
d write com.apple.finder ShowStatusBar -bool true
d write com.apple.finder FXPreferredViewStyle -string "Nlsv"   # list view
d write com.apple.finder FXEnableExtensionChangeWarning -bool false
d write com.apple.finder _FXSortFoldersFirst -bool true
# Search the current folder by default rather than the whole Mac
d write com.apple.finder FXDefaultSearchScope -string "SCcf"
ok "finder"

# ---- dock -------------------------------------------------------------------
say "dock"
d write com.apple.dock autohide -bool true
d write com.apple.dock autohide-delay -float 0          # no delay before it shows
d write com.apple.dock autohide-time-modifier -float 0.5
d write com.apple.dock tilesize -int 48
d write com.apple.dock show-recents -bool false
d write com.apple.dock mru-spaces -bool false           # stop reordering spaces
ok "dock"

# ---- screenshots ------------------------------------------------------------
say "screenshots"
[ "$DRY" -eq 0 ] && mkdir -p "$HOME/Desktop/Screenshots"
d write com.apple.screencapture location -string "$HOME/Desktop/Screenshots"
d write com.apple.screencapture type -string "png"
d write com.apple.screencapture disable-shadow -bool true
ok "screenshots"

# ---- menu bar and system ----------------------------------------------------
say "system"
d write com.apple.menuextra.battery ShowPercent -string "YES"
d write -g NSDisableAutomaticTermination -bool true
d write com.apple.CrashReporter DialogType -string "none"
# Save to disk by default, not iCloud
d write -g NSDocumentSaveNewDocumentsToCloud -bool false
# Expand the save and print panels by default
d write -g NSNavPanelExpandedStateForSaveMode -bool true
d write -g PMPrintingExpandedStateForPrint -bool true
ok "system"

# ---- NOT applied ------------------------------------------------------------
# LSQuarantine controls the "downloaded from the internet, are you sure?"
# prompt. The WIP script disabled it. That check is a real malware guard on a
# daily driver, so it stays on here; use the `unquarantine` alias for the
# occasional signed-but-unnotarised binary instead.
#
# pmset (sleep, autorestart, lidwake) is deliberately omitted: those suited the
# always-on Linux box, not a laptop that should sleep normally.

if [ "$DRY" -eq 0 ]; then
  say "restarting affected apps"
  for app in Dock Finder SystemUIServer cfprefsd; do
    killall "$app" >/dev/null 2>&1 || true
  done
  ok "done — log out for keyboard and trackpad changes"
else
  ok "dry run — nothing changed"
fi
