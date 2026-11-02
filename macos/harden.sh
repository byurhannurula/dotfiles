#!/usr/bin/env bash
#
# harden.sh — security settings for a Mac with no MDM.
#
#   ./install.sh harden            # or: bash macos/harden.sh
#   ./install.sh harden --undo     # reverse items one by one (asks each)
#   ./install.sh harden --dry      # list what it would ask; changes nothing
#                                  # (also with --undo)
#
# Separate from install.sh: these change system files and need sudo, and a
# machine that later gets MDM should get them from there instead. Each item
# is checked first and asked about only when it is not already in place.
#
# Screen Sharing and Remote Login stay manual (System Settings > General >
# Sharing): Apple blocks turning on Screen Sharing from the command line
# since macOS 12.1, and both should be on only while you need them.
#
# bash 3.2 compatible — macOS ships 3.2 and will never update it.

set -uo pipefail
cd "$(dirname "$0")" || exit 1

say()  { printf '\033[0;34m→\033[0m %s\n' "$1"; }
ok()   { printf '\033[0;32m✓\033[0m %s\n' "$1"; }
warn() { printf '\033[0;33m!\033[0m %s\n' "$1"; }
fail() { printf '\033[0;31m✗\033[0m %s\n' "$1"; FAILED=1; }
FAILED=0

UNDO=0; DRY=0
for arg in "$@"; do
  case "$arg" in
    --undo) UNDO=1 ;;
    --dry)  DRY=1 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

[ "$(uname -s)" = Darwin ] || { echo "macOS only" >&2; exit 1; }
[ "$DRY" -eq 1 ] || [ -t 0 ] || { echo "needs a terminal: every item asks first" >&2; exit 1; }

# shellcheck source=../lib/log.sh
. ../lib/log.sh
start_log harden "$@"

# A dry run answers no to everything, so nothing can change. Every "would
# ask" line is an item not in place yet.
ask() {
  if [ "$DRY" -eq 1 ]; then
    printf '  (dry) would ask: %s\n' "$1"
    return 1
  fi
  printf '  %s [y/N] ' "$1"
  read -r a
  case "$a" in [yY]*) return 0 ;; *) return 1 ;; esac
}
[ "$DRY" -eq 1 ] && say "dry run: nothing changes"

FW=/usr/libexec/ApplicationFirewall/socketfilterfw
SSHD_DROPIN=/etc/ssh/sshd_config.d/010-hardening.conf

lock_delay() { sysadminctl -screenLock status 2>&1 | grep -oE 'immediate|off|[0-9]+ seconds' | tail -1; }

# ---- undo -------------------------------------------------------------------
# Each item asks only when it is currently on, newest items first.
if [ "$UNDO" -eq 1 ]; then
  say "undo: each item asks first, default is no"
  if ! mdutil -s / 2>/dev/null | grep -q 'Indexing enabled' \
     && ask "Turn Spotlight indexing back on? (rebuilds the index in the background)"; then
    sudo mdutil -a -i on >/dev/null && ok "Spotlight indexing on" || fail "mdutil failed"
  fi
  if [ "$(lock_delay)" != "300 seconds" ] && ask "Set the screen lock delay back to 5 minutes?"; then
    sysadminctl -screenLock 300 -password - && ok "screen lock after 5 minutes" || fail "sysadminctl failed"
  fi
  if "$FW" --getallowsigned | grep -q 'downloaded signed software DISABLED' \
     && ask "Let downloaded signed apps accept connections without a prompt again?"; then
    sudo "$FW" --setallowsignedapp on >/dev/null && ok "downloaded signed apps allowed" || fail "socketfilterfw failed"
  fi
  if [ -f "$SSHD_DROPIN" ] && ask "Remove the sshd hardening file? (password login over SSH works again)"; then
    sudo rm -f "$SSHD_DROPIN" && ok "sshd hardening removed"
  fi
  if [ -f /etc/pam.d/sudo_local ] && ask "Turn off Touch ID for sudo?"; then
    sudo rm -f /etc/pam.d/sudo_local && ok "Touch ID for sudo off"
  fi
  if "$FW" --getstealthmode | grep -qE 'is on|enabled' && ask "Turn off stealth mode?"; then
    sudo "$FW" --setstealthmode off >/dev/null && ok "stealth mode off" || fail "socketfilterfw failed"
  fi
  # FileVault is left out on purpose: decrypting is slow, rarely wanted, and
  # one System Settings switch. Same for the firewall itself.
  exit "$FAILED"
fi

# ---- FileVault --------------------------------------------------------------
# With no MDM nothing escrows the recovery key, so it exists only where you
# put it. fdesetup prints it once.
if fdesetup status | grep -q 'FileVault is On'; then
  ok "FileVault is on"
elif ask "Turn on FileVault? (prints a recovery key once; save it in your password manager)"; then
  # To the terminal only: the recovery key must not land in the log file.
  # shellcheck disable=SC2024  # /dev/tty needs no root
  sudo fdesetup enable -user "$USER" >/dev/tty 2>&1 || fail "fdesetup failed"
fi

# ---- firewall ---------------------------------------------------------------
# Stealth mode: no reply to ping or to probes of closed ports, which matters
# on office and public Wi-Fi.
if "$FW" --getglobalstate | grep -q enabled && "$FW" --getstealthmode | grep -qE 'is on|enabled'; then
  ok "firewall and stealth mode are on"
elif ask "Turn on the firewall and stealth mode?"; then
  sudo "$FW" --setglobalstate on >/dev/null && sudo "$FW" --setstealthmode on >/dev/null \
    && ok "firewall and stealth mode on" || fail "socketfilterfw failed"
fi

# ---- firewall: downloaded apps ---------------------------------------------
# By default any downloaded app with a valid signature may accept incoming
# connections and no prompt shows. Off, a new app asks once; Apple's own
# software is still allowed.
if "$FW" --getallowsigned | grep -q 'downloaded signed software DISABLED'; then
  ok "downloaded signed apps must ask before they accept connections"
elif ask "Make downloaded signed apps ask before they accept connections?"; then
  sudo "$FW" --setallowsignedapp off >/dev/null \
    && ok "downloaded signed apps now ask" || fail "socketfilterfw failed"
fi

# ---- screen lock ------------------------------------------------------------
# Password after 5 seconds of sleep or screen saver, not the stock 5 minutes.
# sysadminctl asks for your login password; it does not use sudo.
case "$(lock_delay)" in
  immediate|[0-5]\ seconds) ok "screen locks within 5 seconds" ;;
  *)
    if ask "Ask for the password 5 seconds after sleep? (now: $(lock_delay))"; then
      sysadminctl -screenLock 5 -password - && ok "screen lock after 5 seconds" || fail "sysadminctl failed"
    fi ;;
esac

# ---- Spotlight index --------------------------------------------------------
# Raycast replaces Spotlight. With the index off, Raycast file search and Mail
# search find nothing; --undo turns it back on.
if ! mdutil -s / 2>/dev/null | grep -q 'Indexing enabled'; then
  ok "Spotlight indexing is off"
elif ask "Turn off Spotlight indexing on every volume?"; then
  sudo mdutil -a -i off >/dev/null && ok "Spotlight indexing off" || fail "mdutil failed"
fi

# ---- Touch ID for sudo ------------------------------------------------------
# sudo_local survives macOS updates; editing /etc/pam.d/sudo does not.
if grep -qE '^auth[[:space:]].*pam_tid\.so' /etc/pam.d/sudo_local 2>/dev/null; then
  ok "Touch ID for sudo is on"
elif [ ! -f /etc/pam.d/sudo_local.template ]; then
  warn "no /etc/pam.d/sudo_local.template (needs macOS 14 or later)"
elif ask "Use Touch ID for sudo?"; then
  sed 's/^#auth/auth/' /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local >/dev/null \
    && ok "Touch ID for sudo on" || fail "could not write /etc/pam.d/sudo_local"
fi

# ---- sshd -------------------------------------------------------------------
# Applies only while Remote Login is on, but is installed now so turning it on
# later never exposes password login.
dest=$SSHD_DROPIN
want=$(sed "s/__USER__/$USER/" sshd/010-hardening.conf)
if [ "$(cat "$dest" 2>/dev/null)" = "$want" ]; then
  ok "sshd allows keys only, for $USER only"
elif ask "Install the sshd hardening file? (keys only, no root, only $USER)"; then
  [ -s "$HOME/.ssh/authorized_keys" ] \
    || warn "$HOME/.ssh/authorized_keys is empty: no one can log in over SSH until you add a key"
  printf '%s\n' "$want" | sudo tee "$dest" >/dev/null
  # A broken file stops sshd from accepting any connection; undo it.
  if sudo sshd -t; then
    ok "sshd hardening installed"
  else
    sudo rm -f "$dest"
    fail "sshd -t rejected the file; removed it"
  fi
fi

# ---- sharing ----------------------------------------------------------------
# Report only: these are turned on and off by hand, in System Settings >
# General > Sharing. The same switch turns each one back on.
for p in 22:"Remote Login (ssh)" 5900:"Screen Sharing" 445:"File Sharing (SMB)"; do
  if netstat -anp tcp | grep LISTEN | grep -q "\.${p%%:*} "; then
    warn "${p#*:} is on (port ${p%%:*}); turn it off in System Settings when you do not need it"
  else
    ok "${p#*:} is off"
  fi
done

# ---- updates ----------------------------------------------------------------
# Report only: installing restarts the Mac. Values are from the last check.
SU=/Library/Preferences/com.apple.SoftwareUpdate
n=$(defaults read "$SU" LastRecommendedUpdatesAvailable 2>/dev/null || echo 0)
if [ "${n:-0}" -gt 0 ]; then
  warn "$n macOS updates pending: System Settings > General > Software Update"
  err=$(defaults read "$SU" DDMPersistedErrorKey 2>/dev/null | sed -n 's/.*reason = "\(.*\)";/\1/p')
  [ -n "$err" ] && warn "  last install failed: $err (details: softwareupdate -ia --verbose)"
else
  ok "no pending macOS updates"
fi

exit "$FAILED"
