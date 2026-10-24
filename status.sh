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
  if [ "$(git config --global commit.gpgsign)" = true ]; then
    key=$(git config --global user.signingkey)
    key=${key/#\~/$HOME}
    [ -f "$key" ] && yes_ "commit signing" "$(git config --global gpg.format) ${key/#$HOME/~}" \
                  || no_ "commit signing" "key missing: $key"
  else
    no_ "commit signing" "commit.gpgsign is not true"
  fi
  pub=$(ls "$HOME"/.ssh/id_*.pub 2>/dev/null | head -1)
  [ -n "$pub" ] && yes_ "ssh key" "${pub/#$HOME/~}" || no_ "ssh key" "copy from Bitwarden or ssh-keygen -t ed25519"
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
  if has tailscale; then
    tailscale status >/dev/null 2>&1 && yes_ "Tailscale" "connected" || diff_ "Tailscale" "installed, not connected"
  elif [ -d /Applications/Tailscale.app ]; then
    diff_ "Tailscale" "app installed; CLI not on PATH"
  else
    no_ "Tailscale" "brew install --cask tailscale-app"
  fi
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
# Same pairs install.sh copies. "differs" means ~ was edited after install,
# or the repo moved on: copy whichever side is newer over the other.
head_ "Config (repo vs home)"
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
$OS/zed/settings.json|$HOME/.config/zed/settings.json
claude/CLAUDE.md|$HOME/.claude/CLAUDE.md
claude/settings.json|$HOME/.claude/settings.json
shared/opencode/opencode.json|$HOME/.config/opencode/opencode.json"
[ "$OS" = macos ] && pairs="$pairs
macos/ghostty/config|$HOME/Library/Application Support/com.mitchellh.ghostty/config"

echo "$pairs" | while IFS='|' read -r src dest; do
  [ -f "$src" ] || continue
  if [ ! -e "$dest" ]; then
    no_ "$src" "not installed"
  elif cmp -s "$src" "$dest"; then
    yes_ "$src"
  else
    diff_ "$src" "differs from ${dest/#$HOME/~}"
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
