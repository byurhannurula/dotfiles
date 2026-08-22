#!/usr/bin/env bash
#
# install.sh — copy the config in this repo into place.
#
#   ./install.sh                    # ask before each group
#   ./install.sh -y                 # accept everything
#   ./install.sh --hostname bbn-mbp # set the hostname too
#
# Copies, never symlinks: edits to ~ stay local until you copy them back.
# Anything replaced is kept in ~/.dotfiles.backup/<timestamp>/.
#
# bash 3.2 compatible — macOS ships 3.2 and will never update it.

set -uo pipefail
cd "$(dirname "$0")" || exit 1

say()  { printf '\033[0;34m→\033[0m %s\n' "$1"; }
ok()   { printf '\033[0;32m✓\033[0m %s\n' "$1"; }
warn() { printf '\033[0;33m!\033[0m %s\n' "$1"; }

case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)  OS=linux ;;
  *) echo "unsupported: $(uname -s)" >&2; exit 1 ;;
esac

YES=0
HOSTNAME_NEW=""

# Interactivity is DERIVED, not configured: no TTY on stdin means no prompt can
# be answered, so every `read` would return empty and each question would
# silently self-answer. CI is separately explicit, because some steps are safe
# to run unattended but wrong to run on a real machine's login shell.
INTERACTIVE=0
[ -t 0 ] && INTERACTIVE=1
IS_CI="${CI:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    -y|--yes)   YES=1; shift ;;
    --hostname) HOSTNAME_NEW="${2:?--hostname needs a name}"; shift 2 ;;
    -h|--help)  sed -n '3,12p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

BACKUP="$HOME/.dotfiles.backup/$(date +%Y%m%d_%H%M%S)"

# Obsidian keeps its config inside the vault. Override if yours lives elsewhere.
OBSIDIAN_VAULT="${OBSIDIAN_VAULT:-$HOME/Documents/obsidian-bbn}"

ask() {
  [ "$YES" -eq 1 ] && return 0
  [ "$INTERACTIVE" -eq 0 ] && return 1   # nothing to read from; decline
  printf '  %s [y/N] ' "$1"
  read -r a
  case "$a" in [yY]*) return 0 ;; *) return 1 ;; esac
}

# copy SRC -> DEST, backing up whatever is there
put() {
  src=$1; dest=$2
  [ -f "$src" ] || return 0
  if [ -e "$dest" ]; then
    mkdir -p "$BACKUP/$(dirname "${dest#$HOME/}")"
    cp "$dest" "$BACKUP/${dest#$HOME/}" 2>/dev/null
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest" && printf '    %s\n' "${dest#$HOME/}"
}

# ---- preflight --------------------------------------------------------------
# Homebrew, git and the plugin clones all need the Command Line Tools. On a
# fresh Mac they are absent and the installer opens a GUI dialog, so trigger
# it here rather than letting brew fail three steps later.
if [ "$OS" = macos ] && ! xcode-select -p >/dev/null 2>&1; then
  say "installing Xcode Command Line Tools"
  xcode-select --install 2>/dev/null || true
  if [ "$INTERACTIVE" -eq 1 ]; then
    printf '  finish the GUI installer, then press enter: '
    read -r _
  fi
fi

say "installing $OS config from $(pwd)"
echo

# =============================================================================
# Order matters on a fresh machine:
#   1 defaults   before anything opens a window
#   2 hostname   before certs and Tailscale see the old name
#   3 packages   installs zsh, git, code, ghostty... everything below needs them
#   4 oh-my-zsh  needs git from step 3
#   5 shell      .zshrc references the plugins from step 4
#   6 app config the apps exist only after step 3
#   7 extensions needs the `code` binary from step 3
#   4 dock       needs the apps from step 3 to exist
#   9 agents     last; independent of the rest
# =============================================================================

# ---- macOS defaults ---------------------------------------------------------
if [ "$OS" = macos ] && ask "1/9  Apply macOS defaults (finder, dock, pointer, text input)?"; then
  bash macos/defaults.sh
fi

# ---- 2. hostname ------------------------------------------------------------
# Asked rather than assumed: one repo serves several machines and the hostname
# is the thing that must differ. Renaming is behind its own y/N because a
# stray keystroke at a bare prompt would otherwise rename the machine.
if [ -z "$HOSTNAME_NEW" ] && [ "$YES" -eq 0 ] && [ "$INTERACTIVE" -eq 1 ]; then
  current=$(hostname -s 2>/dev/null || hostname)
  if ask "2/9  Change the hostname? (currently: $current)"; then
    printf '      new hostname: '
    read -r HOSTNAME_NEW
  fi
fi

if [ -n "$HOSTNAME_NEW" ]; then
  current=$(hostname -s 2>/dev/null || hostname)
  # Reject anything that is not a plausible hostname before handing it to sudo.
  case "$HOSTNAME_NEW" in
    "$current") say "hostname unchanged" ;;
    *[!a-zA-Z0-9-]*|-*|"")
      warn "not a valid hostname: '$HOSTNAME_NEW' — skipped" ;;
    *)
      if [ "$OS" = macos ]; then
        sudo scutil --set HostName      "$HOSTNAME_NEW"
        sudo scutil --set LocalHostName "$HOSTNAME_NEW"
        sudo scutil --set ComputerName  "$HOSTNAME_NEW"
      else
        sudo hostnamectl set-hostname "$HOSTNAME_NEW"
      fi
      ok "hostname: $HOSTNAME_NEW"
      ;;
  esac
fi

# ---- packages ---------------------------------------------------------------
# This is what the old nix-darwin config did and the first bash draft did not:
# actually install the software. The Brewfile is generated from a capture, so
# it reflects what the machine really had, not a guess.
if [ "$OS" = macos ] && ask "3/9  Install all packages and apps from macos/Brewfile (slow)?"; then
  # Nothing else can bootstrap Homebrew, and everything below depends on it.
  if ! command -v brew >/dev/null 2>&1; then
    say "installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
      || warn "Homebrew install failed"
    [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  if command -v brew >/dev/null 2>&1; then
    # Third-party taps need explicit trust or their formulae are SKIPPED
    # SILENTLY — no error, the package is simply never installed.
    say "trusting taps"
    for t in adembc/tap hashicorp/tap metafab/tap ngrok/ngrok \
             terraform-linters/tap stripe/stripe-cli; do
      brew tap "$t" >/dev/null 2>&1 || warn "tap failed: $t"
    done
    say "brew bundle — this takes a while"
    brew bundle --file=macos/Brewfile || warn "some packages failed; see above"
    ok "packages"
  else
    warn "Homebrew still unavailable — skipping packages"
  fi
fi

if [ "$OS" = linux ] && ask "3/9  Install packages from linux/packages.txt?"; then
  if [ -f linux/packages.txt ]; then
    # strip comments and blank lines, install in one transaction
    pkgs=$(grep -vE '^\s*(#|$)' linux/packages.txt | tr '\n' ' ')
    sudo apt update && sudo apt install -y $pkgs || warn "some packages failed"
    ok "packages"
  else
    warn "linux/packages.txt not found"
  fi
fi

# ---- dock -------------------------------------------------------------------
# Deliberately after the Brewfile step, unlike defaults.sh which runs first:
# dock.sh skips apps that are not installed, so running it early would leave
# an empty Dock.
if [ "$OS" = macos ] && [ -z "$IS_CI" ] && ask "4/9  Set Dock contents from macos/dock.txt?"; then
  bash macos/dock.sh
fi

# ---- git hooks ---------------------------------------------------------------
# .git/hooks/ is not tracked by git, so a hook committed to the repo does
# nothing until core.hooksPath points at it. That is why this belongs in the
# installer rather than being a one-time manual step.
if [ -d .githooks ] && [ -d .git ]; then
  if [ "$(git config core.hooksPath 2>/dev/null)" = ".githooks" ]; then
    say "git hooks already enabled"
  else
    git config core.hooksPath .githooks && ok "git hooks enabled (gitleaks pre-commit)"
  fi
  command -v gitleaks >/dev/null 2>&1 || warn "gitleaks not installed — the hook will skip until it is"
fi

# ---- oh-my-zsh plugins ------------------------------------------------------
# Four plugins in plugins= are not bundled. Without them the shell still
# works, but autosuggestions and syntax highlighting silently do nothing.
if ask "5/9  Install oh-my-zsh and its plugins?"; then
  ZC="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  # On a fresh machine oh-my-zsh is not there yet. Install it unattended:
  # --unattended skips both the "change your shell?" prompt and the exec zsh
  # at the end, either of which would stop this script dead.
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    say "installing oh-my-zsh"
    RUNZSH=no CHSH=no sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
      "" --unattended >/dev/null 2>&1 || warn "oh-my-zsh install failed"
  fi

  if [ -d "$HOME/.oh-my-zsh" ]; then
    for repo in zsh-autosuggestions zsh-syntax-highlighting zsh-completions; do
      if [ -d "$ZC/plugins/$repo" ]; then
        printf '    %s (already there)\n' "$repo"
      else
        git clone -q --depth=1 "https://github.com/zsh-users/$repo" \
          "$ZC/plugins/$repo" && printf '    %s\n' "$repo"
      fi
    done
    # zsh must be the login shell or none of this config is ever read.
    if [ "$(basename "${SHELL:-}")" != zsh ] && command -v zsh >/dev/null 2>&1; then
      if [ -z "$IS_CI" ] && ask "    make zsh the login shell?"; then
        Z=$(command -v zsh)
        grep -qx "$Z" /etc/shells 2>/dev/null || echo "$Z" | sudo tee -a /etc/shells >/dev/null
        chsh -s "$Z" && ok "login shell: $Z (next login)"
      fi
    fi
    ok "oh-my-zsh and plugins"
  else
    warn "oh-my-zsh unavailable — skipping plugins"
  fi
fi

# ---- shell ------------------------------------------------------------------
if ask "6/9  Install shell config (.zshrc, aliases, git)?"; then
  put shared/zshrc.common "$HOME/.zshrc.common"
  put "$OS/.zshrc"        "$HOME/.zshrc"
  put shared/.zprofile    "$HOME/.zprofile"
  put shared/.zshenv      "$HOME/.zshenv"
  put shared/.profile     "$HOME/.profile"
  put shared/.gitconfig   "$HOME/.gitconfig"
  put shared/gitignore_global "$HOME/.gitignore-global"

  if [ -d "$HOME/.oh-my-zsh" ]; then
    C="$HOME/.oh-my-zsh/custom"
    put shared/aliases.zsh        "$C/aliases.zsh"
    put "$OS/aliases.$OS.zsh"     "$C/aliases.$OS.zsh"
  else
    warn "oh-my-zsh not installed — aliases not placed"
    warn "  sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
  fi
  ok "shell"
fi

# ---- apps -------------------------------------------------------------------
if ask "7/9  Install app config (ghostty, vscode, zed, btop, obsidian)?"; then
  if [ "$OS" = macos ]; then
    put macos/ghostty/config "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
    V="$HOME/Library/Application Support/Code/User"
  else
    put linux/ghostty/config "$HOME/.config/ghostty/config"
    V="$HOME/.config/Code/User"
  fi
  put "$OS/vscode/settings.json"    "$V/settings.json"
  put "$OS/vscode/keybindings.json" "$V/keybindings.json"
  put "$OS/zed/settings.json"       "$HOME/.config/zed/settings.json"
  put "$OS/btop/btop.conf"          "$HOME/.config/btop/btop.conf"

  # Obsidian settings live inside the vault, not in ~/Library, so they only
  # apply once the vault exists. Plugin code is not tracked — Obsidian
  # re-downloads it from community-plugins.json on first launch.
  if [ "$OS" = macos ] && [ -d "$OBSIDIAN_VAULT" ]; then
    for f in app.json appearance.json core-plugins.json community-plugins.json \
             hotkeys.json graph.json daily-notes.json templates.json; do
      put "macos/obsidian/$f" "$OBSIDIAN_VAULT/.obsidian/$f"
    done
    ok "obsidian (open the vault to let plugins re-download)"
  elif [ "$OS" = macos ]; then
    warn "obsidian vault not at $OBSIDIAN_VAULT — settings skipped"
  fi
  ok "apps"
fi

# ---- vscode extensions ------------------------------------------------------
# Captured with `code --list-extensions`, so this is what was really installed.
if ask "8/9  Install VS Code extensions ($(wc -l < "$OS/vscode/extensions.txt" 2>/dev/null | tr -d ' ') of them)?"; then
  if command -v code >/dev/null 2>&1; then
    while read -r ext; do
      case "$ext" in ''|\#*) continue ;; esac
      code --install-extension "$ext" --force >/dev/null 2>&1 \
        && printf '    %s\n' "$ext" || warn "failed: $ext"
    done < "$OS/vscode/extensions.txt"
    ok "extensions"
  else
    warn "the 'code' command is not on PATH"
    warn "  VS Code > Cmd-Shift-P > 'Shell Command: Install code command in PATH'"
  fi
fi

# ---- 8. ai harness ----------------------------------------------------------
# Config plus a check that the agents are actually there. The CLIs come from
# the Brewfile in step 3; this catches a machine where that was skipped, and
# handles the ones brew does not carry.
if ask "9/9  Set up AI coding agents (config + verify)?"; then

  # --- config ---
  put claude/CLAUDE.md             "$HOME/.claude/CLAUDE.md"
  put claude/settings.json         "$HOME/.claude/settings.json"
  put claude/statusline-command.sh "$HOME/.claude/statusline-command.sh"
  [ -f "$HOME/.claude/statusline-command.sh" ] && chmod +x "$HOME/.claude/statusline-command.sh"

  for f in opencode.json tui.json; do
    put "shared/opencode/$f" "$HOME/.config/opencode/$f"
  done

  # --- agents ---
  # claude-code and opencode come from the Brewfile. If step 3 was skipped or
  # brew is absent, fall back to each project's own installer.
  if ! command -v claude >/dev/null 2>&1; then
    say "installing claude code"
    if command -v brew >/dev/null 2>&1; then
      brew install --cask claude-code >/dev/null 2>&1 || warn "claude-code failed"
    else
      curl -fsSL https://claude.ai/install.sh | bash >/dev/null 2>&1 \
        || warn "claude install failed — see https://claude.com/product/claude-code"
    fi
  fi

  if ! command -v opencode >/dev/null 2>&1; then
    say "installing opencode"
    if command -v brew >/dev/null 2>&1; then
      brew install opencode >/dev/null 2>&1 || warn "opencode failed"
    else
      curl -fsSL https://opencode.ai/install | bash >/dev/null 2>&1 \
        || warn "opencode install failed — see https://opencode.ai"
    fi
  fi

  # --- report ---
  printf '\n  agent status:\n'
  for a in claude opencode; do
    if command -v "$a" >/dev/null 2>&1; then
      printf '    %-10s %s\n' "$a" "$(command -v "$a")"
    else
      printf '    %-10s not installed\n' "$a"
    fi
  done

  cat <<'NOTE'

  Each agent authenticates on first run — no API key goes in this repo:
    claude              then /login
    opencode auth login

  Not in brew, install by hand if wanted:
    herdr   curl -fsSL https://herdr.dev/install.sh | sh
    pi      npm i -g @earendil-works/pi-coding-agent

NOTE
  ok "ai harness"
fi

echo
[ -d "$BACKUP" ] && say "replaced files backed up to ${BACKUP#$HOME/}"
ok "done — run 'exec zsh' to reload"
