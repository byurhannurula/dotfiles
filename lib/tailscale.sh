# shellcheck shell=bash
# lib/tailscale.sh — sourced by status.sh and macos/always-on.sh, not run.
#
# On macOS the CLI is the app's own binary. Run while the app is not up (a
# new Mac where it was never opened), that binary STARTS the app, which then
# waits for the network extension to be allowed in System Settings, and the
# calling script waits with it. So: read the version from the bundle, ask the
# daemon only when it is running, and cap every call.
#
# bash 3.2 compatible.

TS=""        # the CLI, set by ts_find
TS_APP=""    # the .app bundle, when the CLI is the app's binary

ts_find() {
  TS=$(command -v tailscale 2>/dev/null)
  [ -n "$TS" ] && return 0
  # The app can sit one folder down (Tailscale.localized/) after an update.
  for a in /Applications/Tailscale.app /Applications/*/Tailscale.app; do
    if [ -x "$a/Contents/MacOS/Tailscale" ]; then
      TS="$a/Contents/MacOS/Tailscale"
      TS_APP=$a
      return 0
    fi
  done
  return 1
}

ts_version() {
  if [ -n "$TS_APP" ]; then
    defaults read "$TS_APP/Contents/Info" CFBundleShortVersionString 2>/dev/null
  else
    ts_run version | head -1
  fi
}

# The app variant runs as IPNExtension; the open-source one as tailscaled.
ts_running() { pgrep -q -f 'IPNExtension|tailscaled' 2>/dev/null; }

# ts_run <args...>: the CLI, stopped after 5 seconds.
ts_run() {
  local pid watcher rc
  "$TS" "$@" 2>&1 &
  pid=$!
  # stdout closed, or a $(ts_run ...) would wait for the sleep as well.
  ( sleep 5; kill "$pid" 2>/dev/null ) >/dev/null 2>&1 &
  watcher=$!
  wait "$pid" 2>/dev/null
  rc=$?
  kill "$watcher" 2>/dev/null
  wait "$watcher" 2>/dev/null
  return "$rc"
}
