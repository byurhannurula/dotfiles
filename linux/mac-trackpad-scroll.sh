#!/usr/bin/env bash
# Make the trackpad scroll like a Mac: content follows fingers.
# Re-applied at every login via autostart so the XFCE GUI toggle can't
# silently revert it (libinput's per-device default keeps winning otherwise).
set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }
have xinput || exit 0

for dev in $(xinput list --name-only 2>/dev/null); do
  case "$dev" in
    *TouchPad*|*Touchpad*|*Trackpad*|*bcm5974*|*Synaptics*|*Elantech*|*Alps*) ;;
    *) continue ;;
  esac
  xinput set-prop "$dev" "libinput Natural Scrolling Enabled" 1 2>/dev/null \
    && echo "natural scroll ON: $dev"
done
