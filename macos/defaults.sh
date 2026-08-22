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

# Reads the current value first, so --dry is a real drift report rather than a
# transcript, and a re-run says what actually changed. Note `defaults write`
# exits 0 even when nothing consumes the key, so this compares values instead
# of trusting the exit status.
d() {   # d write <domain> <key> <type> <value>
  local domain key want cur
  domain=$2; key=$3; want=$5
  [ "$domain" = "-g" ] && domain=NSGlobalDomain
  cur=$(defaults read "$domain" "$key" 2>/dev/null)
  # bools read back as 0/1
  case "$want" in
    true)  want=1 ;;
    false) want=0 ;;
  esac
  if [ "$cur" = "$want" ]; then
    [ "$DRY" -eq 1 ] && printf '  same:  %s %s = %s\n' "$domain" "$key" "$cur"
    return 0
  fi
  if [ "$DRY" -eq 1 ]; then
    printf '  set:   %s %s: %s -> %s\n' "$domain" "$key" "${cur:-<unset>}" "$want"
  else
    defaults "$@"
  fi
}
# Some keys are per-host and only resolve with -currentHost.
dh() {
  if [ "$DRY" -eq 1 ]; then
    printf '  would: defaults -currentHost %s\n' "$*"
  else
    defaults -currentHost "$@"
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
d write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false
ok "pointer"

# ---- text input -------------------------------------------------------------
# All five are ON by default and actively corrupt code: smart quotes turn " into
# a curly pair, smart dashes turn -- into an em dash, and autocorrect rewrites
# identifiers. Anything pasted through a Cocoa text field is affected.
say "text input"
d write -g NSAutomaticQuoteSubstitutionEnabled -bool false
d write -g NSAutomaticDashSubstitutionEnabled -bool false
d write -g NSAutomaticSpellingCorrectionEnabled -bool false
d write -g NSAutomaticCapitalizationEnabled -bool false
d write -g NSAutomaticPeriodSubstitutionEnabled -bool false
ok "text input (per-app override, e.g. defaults write md.obsidian NSAutomaticSpellingCorrectionEnabled -bool true)"

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
d write com.apple.finder _FXShowPosixPathInTitle -bool true    # full path in the title bar
# Stop littering network shares and USB sticks with .DS_Store
# https://support.apple.com/en-us/102064
d write com.apple.desktopservices DSDontWriteNetworkStores -bool true
d write com.apple.desktopservices DSDontWriteUSBStores -bool true
ok "finder"

# ---- dock -------------------------------------------------------------------
say "dock"
d write com.apple.dock autohide -bool true
d write com.apple.dock autohide-delay -float 0          # no delay before it shows
d write com.apple.dock autohide-time-modifier -float 0      # 0 = instant; 0.5 is slower than stock
d write com.apple.dock expose-animation-duration -float 0.1
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
d write com.apple.screencapture show-thumbnail -bool false     # no floating preview
ok "screenshots"

# ---- menu bar and system ----------------------------------------------------
say "system"
# Battery moved to Control Center in Big Sur; com.apple.menuextra.battery is a
# dead domain. This key is per-host and takes a bool, not the old "YES" string.
dh write com.apple.controlcenter BatteryShowPercentage -bool true
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
  # cfprefsd is deliberately NOT killed: it is the preferences daemon, and
  # killing it can drop writes still sitting in its cache.
  for app in Dock Finder SystemUIServer ControlCenter; do
    killall "$app" >/dev/null 2>&1 || true
  done
  ok "done — log out for keyboard and trackpad changes"
else
  ok "dry run — nothing changed"
fi
