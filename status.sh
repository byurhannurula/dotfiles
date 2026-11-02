#!/usr/bin/env bash
#
# status.sh — report what this machine has, compared with the repo.
#
#   ./status.sh            # or: ./install.sh status
#
# Read-only: changes nothing, installs nothing, asks nothing.
#
# bash 3.2 compatible — macOS ships 3.2 and will never update it.

set -uo pipefail
cd "$(dirname "$0")" || exit 1

# shellcheck source=lib/log.sh
. lib/log.sh
start_log status "$@"

case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)  OS=linux ;;
  *) echo "unsupported: $(uname -s)" >&2; exit 1 ;;
esac

head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }
row()   { printf '  %-30s %s\n' "$1" "$2"; }
yes_()  { printf '  \033[0;32m✓\033[0m %-28s %s\n' "$1" "${2:-}"; }
no_()   { printf '  \033[0;31m✗\033[0m %-28s %s\n' "$1" "${2:-}"; }
diff_() { printf '  \033[0;33m~\033[0m %-28s %s\n' "$1" "${2:-}"; }
has()   { command -v "$1" >/dev/null 2>&1; }

# Banners differ per tool ("git version 2.x", "jq-1.8", eza's two lines), so
# take the first version-shaped token rather than parsing each format.
ver() { "$@" 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1; }

# ---- machine ----------------------------------------------------------------
head_ "Machine"
if [ "$OS" = macos ]; then
  row "os" "macOS $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
  row "chip" "$(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
  row "memory" "$(( $(sysctl -n hw.memsize) / 1073741824 )) GB"
  row "hostname" "$(scutil --get LocalHostName 2>/dev/null)"
  row "computer name" "$(scutil --get ComputerName 2>/dev/null)"
else
  row "os" "$(. /etc/os-release && echo "$PRETTY_NAME")"
  row "cpu" "$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')"
  row "memory" "$(awk '/MemTotal/ {printf "%d GB", $2/1048576}' /proc/meminfo)"
  row "hostname" "$(hostname)"
fi
row "arch" "$(uname -m)"
# On a fresh Mac, /usr/bin/git and python3 are stubs that open the Command
# Line Tools installer, so nothing below may call them until CLT exists.
CLT=1
if [ "$OS" = macos ]; then
  xcode-select -p >/dev/null 2>&1 && yes_ "command line tools" || { CLT=0; no_ "command line tools" "run: xcode-select --install"; }
fi
row "disk free" "$(df -h "$HOME" | awk 'NR==2 {print $4 " of " $2}')"
row "user" "${USER:-$(id -un)}"
row "login shell" "${SHELL:-?}"

# ---- shell ------------------------------------------------------------------
head_ "Shell"
[ "$(basename "${SHELL:-}")" = zsh ] && yes_ "zsh is login" || no_ "zsh is login" "run: chsh -s \$(command -v zsh)"
[ -d "$HOME/.oh-my-zsh" ] && yes_ "oh-my-zsh" || no_ "oh-my-zsh" "install.sh step 5"
for p in zsh-autosuggestions zsh-syntax-highlighting zsh-completions; do
  [ -d "$HOME/.oh-my-zsh/custom/plugins/$p" ] && yes_ "$p" || no_ "$p" "install.sh step 5"
done

# ---- node -------------------------------------------------------------------
head_ "Node"
if has fnm; then
  yes_ "fnm" "$(ver fnm --version)"
  default=$(readlink "${FNM_DIR:-$HOME/.local/share/fnm}/aliases/default" 2>/dev/null \
    | sed -E 's#.*/(v[0-9.]+)/installation#\1#')
  [ -n "$default" ] && row "default" "$default" || no_ "default" "run: fnm install --lts && fnm default lts-latest"
  row "installed" "$(fnm ls 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | tr '\n' ' ')"
else
  no_ "fnm" "install.sh step 3"
fi
if has node; then
  where=$(command -v node)
  case "$where" in
    *fnm*) row "node" "$(node -v)  $where" ;;
    *)     diff_ "node" "$(node -v)  $where  (not fnm: shell opened before the switch?)" ;;
  esac
fi
[ -d "$HOME/.nvm" ] && diff_ ".nvm" "still present; safe to delete once fnm works"

# ---- tools ------------------------------------------------------------------
head_ "Tools"
for t in git brew gh pnpm python3 go docker betterleaks fzf eza bat rg btop jq; do
  if [ "$CLT" -eq 0 ] && { [ "$t" = git ] || [ "$t" = python3 ]; }; then
    no_ "$t" "needs the Command Line Tools"
  elif has "$t"; then
    case "$t" in
      go) yes_ "$t" "$(ver go version)" ;;
      *)  yes_ "$t" "$(ver "$t" --version)" ;;
    esac
  else
    no_ "$t"
  fi
done

head_ "AI agents"
for t in claude opencode; do
  has "$t" && yes_ "$t" "$(ver "$t" --version)" || no_ "$t" "install.sh step 9"
done

# ---- git and ssh ------------------------------------------------------------
head_ "Git and SSH"
if [ "$CLT" -eq 1 ]; then
  row "user" "$(git config --global user.name) <$(git config --global user.email)>"
  # --includes: --global alone skips ~/.gitconfig.local, where per-machine
  # signing values live.
  gc() { git config --global --includes "$@"; }
  if [ "$(gc commit.gpgsign)" = true ]; then
    key=$(gc user.signingkey)
    key=${key/#\~/$HOME}
    if [ ! -f "$key" ]; then
      no_ "commit signing" "key missing: $key — every commit fails: ./install.sh ssh"
    else
      yes_ "commit signing" "$(gc gpg.format) ${key/#$HOME/~}"
      signers=$(gc gpg.ssh.allowedSignersFile); signers=${signers/#\~/$HOME}
      grep -qF "$(awk '{print $2}' "$key")" "$signers" 2>/dev/null \
        && yes_ "allowed_signers" "has the signing key" \
        || diff_ "allowed_signers" "missing the signing key: ./install.sh ssh"
    fi
  else
    diff_ "commit signing" "off on this machine"
  fi
  pub=$(ls "$HOME"/.ssh/id_*.pub 2>/dev/null | head -1)
  [ -n "$pub" ] && yes_ "ssh key" "${pub/#$HOME/~}" || no_ "ssh key" "./install.sh ssh"
  row "" "details: ./install.sh ssh status"
  [ "$(git config core.hooksPath)" = .githooks ] && yes_ "repo hooks" "secret scan pre-commit" \
    || no_ "repo hooks" "run: git config core.hooksPath .githooks"
else
  no_ "git" "needs the Command Line Tools"
fi

# ---- security ---------------------------------------------------------------
# All without sudo. Fixes are in macos/harden.sh (./install.sh harden).
if [ "$OS" = macos ]; then
  head_ "Security"
  fdesetup status 2>/dev/null | grep -q 'FileVault is On' && yes_ "FileVault" || no_ "FileVault" "./install.sh harden"
  fw=/usr/libexec/ApplicationFirewall/socketfilterfw
  "$fw" --getglobalstate 2>/dev/null | grep -q enabled && yes_ "firewall" || no_ "firewall" "./install.sh harden"
  "$fw" --getstealthmode 2>/dev/null | grep -qE 'is on|enabled' && yes_ "stealth mode" || no_ "stealth mode" "./install.sh harden"
  spctl --status 2>/dev/null | grep -q enabled && yes_ "Gatekeeper" || no_ "Gatekeeper" "run: sudo spctl --global-enable"
  csrutil status 2>/dev/null | grep -q enabled && yes_ "SIP" || no_ "SIP" "turn on from recovery mode"
  grep -qE '^auth[[:space:]].*pam_tid\.so' /etc/pam.d/sudo_local 2>/dev/null \
    && yes_ "Touch ID for sudo" || diff_ "Touch ID for sudo" "off: ./install.sh harden"
  [ -f /etc/ssh/sshd_config.d/010-hardening.conf ] && yes_ "sshd keys only" || diff_ "sshd keys only" "not installed: ./install.sh harden"
  # launchd holds the listening socket while a sharing service is on.
  listening=$(netstat -anp tcp 2>/dev/null | grep LISTEN)
  for p in 22:"Remote Login" 5900:"Screen Sharing"; do
    echo "$listening" | grep -q "\.${p%%:*} " && diff_ "${p#*:}" "on (port ${p%%:*})" || row "${p#*:}" "off"
  done
  echo "$listening" | grep -q '\.445 ' && diff_ "File Sharing (SMB)" "on (port 445)" || row "File Sharing (SMB)" "off"
  "$fw" --getallowsigned 2>/dev/null | grep -q 'downloaded signed software ENABLED' \
    && diff_ "downloaded signed apps" "accept connections unasked: ./install.sh harden" \
    || yes_ "downloaded signed apps" "must ask"
  lock=$(sysadminctl -screenLock status 2>&1 | grep -oE 'immediate|off|[0-9]+ seconds' | tail -1)
  case "$lock" in
    immediate|[0-5]\ seconds) yes_ "screen lock" "$lock" ;;
    *) diff_ "screen lock" "${lock:-unknown}: ./install.sh harden" ;;
  esac
  # A dev server on *: is reachable by everything on the same Wi-Fi.
  # AirPlay (ControlCenter) and Continuity (rapportd) are expected.
  lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null \
    | awk '$9 ~ /^\*:/ && $1 !~ /^(ControlCe|rapportd)/ {print $1, $9}' | sort -u \
    | while read -r cmd addr; do diff_ "open to the network" "$cmd on $addr (bind 127.0.0.1 instead)"; done
  SU=/Library/Preferences/com.apple.SoftwareUpdate
  n=$(defaults read "$SU" LastRecommendedUpdatesAvailable 2>/dev/null || echo 0)
  if [ "${n:-0}" -gt 0 ]; then
    no_ "macOS updates" "$n pending: System Settings > General > Software Update"
    err=$(defaults read "$SU" DDMPersistedErrorKey 2>/dev/null | sed -n 's/.*reason = "\(.*\)";/\1/p')
    [ -n "$err" ] && row "" "last install failed: $err"
  else
    yes_ "macOS updates" "none pending"
  fi

  # shellcheck source=lib/tailscale.sh
  . lib/tailscale.sh
  if ts_find; then
    tsv=$(ts_version)
    # TS-2026-014..017 (Tailscale SSH and Serve) are fixed in 1.104.4.
    if awk -v a="$tsv" 'BEGIN { split(a, x, "."); split("1.104.4", y, ".");
         for (i = 1; i <= 3; i++) { if (x[i]+0 > y[i]+0) exit 0; if (x[i]+0 < y[i]+0) exit 1 } exit 0 }'; then
      yes_ "Tailscale" "$tsv"
    else
      no_ "Tailscale" "${tsv:-unknown}: update to 1.104.4+ (TS-2026-014..017)"
    fi
    if ! ts_running; then
      diff_ "  app" "not running: open Tailscale once and allow its extension"
    else
      ts_run status --json | grep -q '"BackendState": "Running"' \
        && row "  connection" "connected" || row "  connection" "not connected"
      prefs=$(ts_run debug prefs)
      echo "$prefs" | grep -q '"RunSSH": true' \
        && no_ "  Tailscale SSH" "on: tailscale set --ssh=false" || yes_ "  Tailscale SSH" "off"
      # serve status covers Funnel too: Funnel is a flag on a serve entry.
      ts_run serve status | grep -qv 'No serve config' \
        && diff_ "  Serve / Funnel" "on: tailscale serve reset" || yes_ "  Serve / Funnel" "off"
      echo "$prefs" | grep -q '"ShieldsUp": true' \
        && row "  shields up" "on (no incoming)" || row "  shields up" "off (policy decides)"
      echo "$prefs" | grep -qE '"ExitNodeID": "[^"]+"' \
        && row "  exit node" "in use" || row "  exit node" "none"
    fi
  else
    no_ "Tailscale" "brew install --cask tailscale-app"
  fi

  head_ "Privacy"
  [ "$(defaults read com.apple.assistant.support 'Assistant Enabled' 2>/dev/null)" = 0 ] \
    && yes_ "Siri" "off" || diff_ "Siri" "on: ./macos/defaults.sh"
  # Not an Apple-documented key: the opt-in dict holds one numeric feature
  # flag per Apple Intelligence rollout; any 1 means it is on.
  if defaults read com.apple.CloudSubscriptionFeatures.optIn 2>/dev/null | grep -qE '^ *"?[0-9]+"? = 1;'; then
    diff_ "Apple Intelligence" "on: System Settings > Apple Intelligence & Siri"
  else
    yes_ "Apple Intelligence" "off (unofficial check)"
  fi
  mdutil -s / 2>/dev/null | grep -q 'Indexing enabled' \
    && diff_ "Spotlight index" "on: ./install.sh harden" || yes_ "Spotlight index" "off"
  [ "$(/usr/libexec/PlistBuddy -c 'Print :AppleSymbolicHotKeys:64:enabled' \
      "$HOME/Library/Preferences/com.apple.symbolichotkeys.plist" 2>/dev/null)" = false ] \
    && yes_ "Cmd-Space" "free for Raycast" || diff_ "Cmd-Space" "still Spotlight: ./macos/defaults.sh"
  [ "$(defaults read com.apple.AdLib allowIdentifierForAdvertising 2>/dev/null)" = 0 ] \
    && yes_ "ad identifier" "off" || diff_ "ad identifier" "on: ./macos/defaults.sh"
fi

# ---- homebrew ---------------------------------------------------------------
if [ "$OS" = macos ] && has brew; then
  head_ "Homebrew"
  row "version" "$(brew --version | head -1 | awk '{print $2}')"
  row "installed" "$(brew list --formula | wc -l | tr -d ' ') formulae, $(brew list --cask | wc -l | tr -d ' ') casks"
  for bf in Brewfile Brewfile.personal; do
    # One "→" line per unsatisfied entry, on stderr. Apps installed by
    # drag-and-drop count too: brew does not manage them.
    missing=$(brew bundle check --verbose --no-upgrade --file="$bf" 2>&1 | grep -c '^→')
    total=$(grep -cE '^(brew|cask) ' "$bf")
    if [ "$missing" -eq 0 ]; then
      yes_ "$bf" "all $total installed"
    else
      diff_ "$bf" "$missing of $total not installed by brew"
      row "" "list: brew bundle check --verbose --file=$bf"
    fi
  done
fi

# ---- config drift -----------------------------------------------------------
# Same pairs install.sh links. A regular file where a link should be means
# the config was copied (an old install) or an app saved by replacing the
# link: diff it against the repo, keep what you want, then run install.sh.
head_ "Config (linked to repo)"
REPO=$(pwd -P)
V="$HOME/Library/Application Support/Code/User"
[ "$OS" = linux ] && V="$HOME/.config/Code/User"
pairs="shared/zshrc.common|$HOME/.zshrc.common
$OS/.zshrc|$HOME/.zshrc
shared/.zshenv|$HOME/.zshenv
shared/.zprofile|$HOME/.zprofile
shared/.gitconfig|$HOME/.gitconfig
shared/gitignore_global|$HOME/.gitignore-global
shared/aliases.zsh|$HOME/.oh-my-zsh/custom/aliases.zsh
$OS/aliases.$OS.zsh|$HOME/.oh-my-zsh/custom/aliases.$OS.zsh
$OS/vscode/settings.json|$V/settings.json
$OS/vscode/keybindings.json|$V/keybindings.json
$OS/zed/settings.json|$HOME/.config/zed/settings.json
$OS/btop/btop.conf|$HOME/.config/btop/btop.conf
claude/CLAUDE.md|$HOME/.claude/CLAUDE.md
claude/settings.json|$HOME/.claude/settings.json
claude/statusline-command.sh|$HOME/.claude/statusline-command.sh
claude/hooks/git-readonly.py|$HOME/.claude/hooks/git-readonly.py
shared/opencode/opencode.json|$HOME/.config/opencode/opencode.json
shared/opencode/tui.json|$HOME/.config/opencode/tui.json"
[ "$OS" = macos ] && pairs="$pairs
macos/ghostty/config|$HOME/Library/Application Support/com.mitchellh.ghostty/config"

echo "$pairs" | while IFS='|' read -r src dest; do
  [ -f "$src" ] || continue
  if [ "$(readlink "$dest" 2>/dev/null)" = "$REPO/$src" ]; then
    yes_ "$src"
  elif [ -L "$dest" ]; then
    diff_ "$src" "links elsewhere: $(readlink "$dest")"
  elif [ ! -e "$dest" ]; then
    no_ "$src" "not installed"
  elif cmp -s "$src" "$dest"; then
    diff_ "$src" "a copy, not a link: run install.sh"
  else
    diff_ "$src" "a file that differs: diff it, then run install.sh"
  fi
done

# ---- apps -------------------------------------------------------------------
if [ "$OS" = macos ]; then
  head_ "Apps"
  for a in Ghostty "Visual Studio Code" Zed OrbStack Raycast Obsidian Claude "Google Chrome" "Brave Browser"; do
    [ -d "/Applications/$a.app" ] && yes_ "$a" || no_ "$a"
  done
fi
echo
