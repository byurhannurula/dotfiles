#!/usr/bin/env bash
#
# defaults.sh — macOS system preferences.
#
#   ./macos/defaults.sh               # apply
#   ./macos/defaults.sh --dry         # print what would change, touch nothing
#   ./macos/defaults.sh --undo FILE   # restore the values a run replaced
#
# Each run that changes something writes an undo file to ~/.dotfiles.backup/
# and prints its path. It holds the old value of each key it changed, or a
# delete for a key that was not set before.
#
# Values marked "captured" are read from the daily-driver Mac on 2026-08-22. The rest come
# from the earlier WIP setup and are sensible defaults, not current state.
#
# Log out for the keyboard and trackpad settings to take effect.

set -uo pipefail

DRY=0
UNDO_FROM=""
case "${1:-}" in
  --dry)  DRY=1 ;;
  --undo) UNDO_FROM="${2:?--undo needs the file path that a run printed}" ;;
esac

UNDO="$HOME/.dotfiles.backup/defaults-$(date +%Y%m%d_%H%M%S).sh"
undo_line() {
  [ "$DRY" -eq 1 ] && return 0
  if [ ! -f "$UNDO" ]; then
    mkdir -p "$(dirname "$UNDO")"
    printf '#!/usr/bin/env bash\n# Restores what macos/defaults.sh changed on %s\n' "$(date)" > "$UNDO"
  fi
  printf '%s\n' "$1" >> "$UNDO"
}

# Reads the current value first, so --dry is a real drift report rather than a
# transcript, and a re-run says what actually changed. Note `defaults write`
# exits 0 even when nothing consumes the key, so this compares values instead
# of trusting the exit status.
d() {   # d [-currentHost] write <domain> <key> <type> <value>
  local ch="" domain key type want cur old had=1
  if [ "$1" = -currentHost ]; then ch=-currentHost; shift; fi
  domain=$2; key=$3; type=$4; want=$5
  [ "$domain" = "-g" ] && domain=NSGlobalDomain
  cur=$(defaults $ch read "$domain" "$key" 2>/dev/null) || { had=0; cur=""; }
  # bools read back as 0/1
  case "$want" in
    true)  want=1 ;;
    false) want=0 ;;
  esac
  if [ "$had" -eq 1 ] && [ "$cur" = "$want" ]; then
    [ "$DRY" -eq 1 ] && printf '  same:  %s %s = %s\n' "$domain" "$key" "$cur"
    return 0
  fi
  if [ "$DRY" -eq 1 ]; then
    printf '  set:   %s %s: %s -> %s\n' "$domain" "$key" "${cur:-<unset>}" "$want"
    return 0
  fi
  if [ "$had" -eq 0 ]; then
    undo_line "defaults $ch delete $(printf %q "$domain") $(printf %q "$key")"
  else
    old=$cur
    [ "$type" = -bool ] && { [ "$old" = 1 ] && old=true || old=false; }
    undo_line "defaults $ch write $(printf %q "$domain") $(printf %q "$key") $type $(printf %q "$old")"
  fi
  defaults $ch "$@"
}
# Some keys are per-host and only resolve with -currentHost.
dh() { d -currentHost "$@"; }

# Symbolic hotkeys are nested dicts, which d() cannot compare.
# The modifier masks are Apple's stock values: Cmd = 1048576, Opt-Cmd = 1572864.
HOTKEYS=$HOME/Library/Preferences/com.apple.symbolichotkeys.plist
HOTKEYS_CHANGED=0
hotkey_entry() {   # <true|false> <modifier mask>; 49 is the space bar
  printf '<dict><key>enabled</key><%s/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>%s</integer></array><key>type</key><string>standard</string></dict></dict>' "$1" "$2"
}
hotkey_off() {   # hotkey_off <id> <modifier mask>
  local cur
  cur=$(/usr/libexec/PlistBuddy -c "Print :AppleSymbolicHotKeys:$1:enabled" "$HOTKEYS" 2>/dev/null)
  if [ "$cur" = false ]; then
    [ "$DRY" -eq 1 ] && printf '  same:  hotkey %s off\n' "$1"
    return 0
  fi
  if [ "$DRY" -eq 1 ]; then
    printf '  set:   hotkey %s: %s -> off\n' "$1" "${cur:-<unset>}"
    return 0
  fi
  undo_line "defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add $1 '$(hotkey_entry true "$2")'"
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$1" "$(hotkey_entry false "$2")"
  HOTKEYS_CHANGED=1
}
say() { printf '\033[0;34m→\033[0m %s\n' "$1"; }
ok()  { printf '\033[0;32m✓\033[0m %s\n' "$1"; }

[ "$(uname -s)" = Darwin ] || { echo "macOS only" >&2; exit 1; }

restart_apps() {
  say "restarting affected apps"
  # cfprefsd is deliberately NOT killed: it is the preferences daemon, and
  # killing it can drop writes still sitting in its cache.
  for app in Dock Finder SystemUIServer ControlCenter; do
    killall "$app" >/dev/null 2>&1 || true
  done
}

if [ -n "$UNDO_FROM" ]; then
  [ -f "$UNDO_FROM" ] || { echo "no such file: $UNDO_FROM" >&2; exit 1; }
  say "restoring from $UNDO_FROM"
  bash "$UNDO_FROM" || { echo "some keys did not restore; see above" >&2; exit 1; }
  restart_apps
  ok "restored — log out for keyboard, trackpad and hotkey changes"
  exit 0
fi

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

# ---- siri, spotlight, ads ---------------------------------------------------
# Raycast replaces Spotlight, so its shortcuts go. The index itself is turned
# off in harden.sh, because mdutil needs sudo.
#
# Apple Intelligence has no supported key outside MDM: the Writing Tools and
# Genmoji restrictions apply only to enrolled Macs. Turn it off in System
# Settings > Apple Intelligence & Siri; status.sh reports if it comes back.
say "siri, spotlight, ads"
d write com.apple.assistant.support "Assistant Enabled" -bool false
d write com.apple.Siri StatusMenuVisible -bool false
d write com.apple.Siri VoiceTriggerUserEnabled -bool false    # "Hey Siri"
d write com.apple.Siri LockscreenEnabled -bool false
hotkey_off 64 1048576     # Cmd-Space: Spotlight
hotkey_off 65 1572864     # Opt-Cmd-Space: Finder search window
# Look Up sends the selected text to Apple for web suggestions.
d write com.apple.lookup.shared LookupSuggestionsDisabled -bool true
d write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
d write com.apple.AdLib allowIdentifierForAdvertising -bool false
# AirPlay Receiver stays on: it receives from the iPhone.
ok "siri, spotlight, ads"

# ---- NOT applied ------------------------------------------------------------
# LSQuarantine controls the "downloaded from the internet, are you sure?"
# prompt. The WIP script disabled it. That check is a real malware guard on a
# daily driver, so it stays on here; use the `unquarantine` alias for the
# occasional signed-but-unnotarised binary instead.
#
# pmset (sleep, autorestart, lidwake) is deliberately omitted: those suited the
# always-on Linux box, not a laptop that should sleep normally.

if [ "$DRY" -eq 0 ]; then
  restart_apps
  # Without this, hotkey changes wait for the next login.
  [ "$HOTKEYS_CHANGED" -eq 1 ] && \
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null
  [ -f "$UNDO" ] && ok "undo: ./macos/defaults.sh --undo ${UNDO/#$HOME/~}"
  ok "done — log out for keyboard and trackpad changes"
else
  ok "dry run — nothing changed"
fi
