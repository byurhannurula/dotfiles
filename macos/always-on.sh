#!/usr/bin/env bash
#
# always-on.sh — keep a MacBook reachable while it sits closed on a desk.
#
#   ./install.sh always-on                 # or: bash macos/always-on.sh
#   ./install.sh always-on --undo FILE     # restore what a run changed
#   ./install.sh always-on --dry           # list what it would ask; changes nothing
#
# For the work laptop that stays at the office and is driven over Tailscale.
# Not for a laptop you carry: it stops sleep while on the charger.
#
# Hardware it assumes: a charger of its own (not the monitor's USB-C, which
# stops when the monitor is off) and an HDMI dummy plug, so the closed laptop
# stays in clamshell mode. With both, `pmset disablesleep` is not needed.
#
# bash 3.2 compatible — macOS ships 3.2 and will never update it.

set -uo pipefail
cd "$(dirname "$0")" || exit 1

say()  { printf '\033[0;34m→\033[0m %s\n' "$1"; }
ok()   { printf '\033[0;32m✓\033[0m %s\n' "$1"; }
warn() { printf '\033[0;33m!\033[0m %s\n' "$1"; }
fail() { printf '\033[0;31m✗\033[0m %s\n' "$1"; FAILED=1; }
FAILED=0

[ "$(uname -s)" = Darwin ] || { echo "macOS only" >&2; exit 1; }

ARGS="$*"
DRY=0; UNDO_FROM=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry)  DRY=1; shift ;;
    --undo) UNDO_FROM="${2:?--undo needs the file path that a run printed}"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

# shellcheck source=../lib/log.sh
. ../lib/log.sh
start_log always-on "$ARGS"

if [ -n "$UNDO_FROM" ]; then
  [ -f "$UNDO_FROM" ] || { echo "no such file: $UNDO_FROM" >&2; exit 1; }
  if [ "$DRY" -eq 1 ]; then
    say "dry run: would run these lines from $UNDO_FROM"
    grep -v '^#' "$UNDO_FROM" | sed 's/^/    /'
    exit 0
  fi
  say "restoring from $UNDO_FROM"
  bash "$UNDO_FROM" && ok "restored" || { fail "some settings did not restore"; exit 1; }
  exit 0
fi

[ "$DRY" -eq 1 ] || [ -t 0 ] || { echo "needs a terminal: every item asks first" >&2; exit 1; }

# A dry run answers no to everything, so nothing can change.
ask() {
  if [ "$DRY" -eq 1 ]; then
    printf '  (dry) would ask: %s\n' "$1"
    return 1
  fi
  printf '  %s [y/N] ' "$1"
  read -r a
  case "$a" in [yY]*) return 0 ;; *) return 1 ;; esac
}

UNDO="$HOME/.dotfiles.backup/always-on-$(date +%Y%m%d_%H%M%S).sh"
undo_line() {
  if [ ! -f "$UNDO" ]; then
    mkdir -p "$(dirname "$UNDO")"
    printf '#!/usr/bin/env bash\n# Restores what macos/always-on.sh changed on %s\n' "$(date)" > "$UNDO"
  fi
  printf '%s\n' "$1" >> "$UNDO"
}

if [ "$DRY" -eq 1 ]; then
  say "dry run: nothing changes"
else
  ask "This Mac stays at a desk on its own charger and is reached remotely?" \
    || { echo "  nothing changed"; exit 0; }
fi

# ---- sleep on the charger ---------------------------------------------------
# -c is the charger profile only. On battery (a power cut) the Mac still
# sleeps, which keeps the battery from running flat.
ac() { pmset -g custom | awk -v k="$1" '/^AC Power:/ {f=1; next} /Power:$/ {f=0} f && $1 == k {print $2}'; }
want="sleep:0 disksleep:0 womp:1"
change=""
for kv in $want; do
  k=${kv%%:*}; v=${kv#*:}
  [ "$(ac "$k")" = "$v" ] || change="$change $kv"
done
if [ -z "$change" ]; then
  ok "on the charger: no system or disk sleep; wake for network on"
elif ask "On the charger: no system or disk sleep, wake for network access?"; then
  for kv in $change; do
    k=${kv%%:*}; v=${kv#*:}
    old=$(ac "$k")
    [ -n "$old" ] && undo_line "sudo pmset -c $k $old"
    sudo pmset -c "$k" "$v" || fail "pmset $k failed"
  done
  ok "charger sleep settings (the display still sleeps)"
fi

# ---- macOS updates ----------------------------------------------------------
# An update restart locks the disk behind FileVault, and Tailscale cannot
# start until someone unlocks it. Download on its own, install by hand with
# an authenticated restart (`authrestart` alias), which unlocks once by itself.
# Security responses stay automatic.
SU=/Library/Preferences/com.apple.SoftwareUpdate
cur=$(defaults read "$SU" AutomaticallyInstallMacOSUpdates 2>/dev/null)
if [ "$cur" = 0 ]; then
  ok "macOS updates download only; install with: authrestart"
elif ask "Stop macOS from installing updates and restarting on its own?"; then
  if [ -n "$cur" ]; then
    undo_line "sudo defaults write $SU AutomaticallyInstallMacOSUpdates -bool $([ "$cur" = 1 ] && echo true || echo false)"
  else
    undo_line "sudo defaults delete $SU AutomaticallyInstallMacOSUpdates"
  fi
  sudo defaults write "$SU" AutomaticallyInstallMacOSUpdates -bool false \
    && ok "updates download only" || fail "could not write $SU"
fi

# ---- report only ------------------------------------------------------------
fdesetup supportsauthrestart 2>/dev/null | grep -q true \
  && ok "authenticated restart supported" \
  || warn "authenticated restart not supported: every restart needs an unlock at the Mac"

# Remote Login is the way in when T3 Code is down, and on macOS 26 the
# office-LAN path to unlock FileVault after a crash.
if netstat -anp tcp 2>/dev/null | grep LISTEN | grep -q '\.22 '; then
  [ -f /etc/ssh/sshd_config.d/010-hardening.conf ] \
    && ok "Remote Login on, keys only" \
    || warn "Remote Login on without the keys-only file: ./install.sh harden"
else
  warn "Remote Login is off: System Settings > General > Sharing"
fi

TS=$(command -v tailscale 2>/dev/null)
for a in /Applications/Tailscale.app /Applications/*/Tailscale.app; do
  [ -n "$TS" ] && break
  [ -x "$a/Contents/MacOS/Tailscale" ] && TS="$a/Contents/MacOS/Tailscale"
done
if [ -z "$TS" ]; then
  warn "Tailscale not installed"
elif "$TS" debug prefs 2>/dev/null | grep -q '"ShieldsUp": true'; then
  warn "Tailscale Shields Up is on: nothing can connect. Turn it off: tailscale set --shields-up=false"
else
  ok "Tailscale accepts connections (the tailnet policy decides who)"
fi

warn "test once: restart here at the desk, unlock, then reach this Mac from the phone"
[ -f "$UNDO" ] && ok "undo: ./install.sh always-on --undo ${UNDO/#$HOME/~}"
exit "$FAILED"
