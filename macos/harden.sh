#!/usr/bin/env bash
#
# harden.sh — security settings for a Mac with no MDM.
#
#   ./install.sh harden     # or: bash macos/harden.sh
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

[ "$(uname -s)" = Darwin ] || { echo "macOS only" >&2; exit 1; }
[ -t 0 ] || { echo "needs a terminal: every item asks first" >&2; exit 1; }

ask() {
  printf '  %s [y/N] ' "$1"
  read -r a
  case "$a" in [yY]*) return 0 ;; *) return 1 ;; esac
}

FW=/usr/libexec/ApplicationFirewall/socketfilterfw

# ---- FileVault --------------------------------------------------------------
# With no MDM nothing escrows the recovery key, so it exists only where you
# put it. fdesetup prints it once.
if fdesetup status | grep -q 'FileVault is On'; then
  ok "FileVault is on"
elif ask "Turn on FileVault? (prints a recovery key once; save it in your password manager)"; then
  sudo fdesetup enable -user "$USER" || fail "fdesetup failed"
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
dest=/etc/ssh/sshd_config.d/010-hardening.conf
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
# Report only: these are turned on and off by hand.
for p in 22:"Remote Login (ssh)" 5900:"Screen Sharing"; do
  if netstat -anp tcp | grep LISTEN | grep -q "\.${p%%:*} "; then
    warn "${p#*:} is on (port ${p%%:*}); turn it off in System Settings when you do not need it"
  else
    ok "${p#*:} is off"
  fi
done

exit "$FAILED"
