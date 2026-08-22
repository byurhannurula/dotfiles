# =============================================================================
# .zprofile — login shells only. Runs before .zshrc.
#
# Homebrew must be set up here: it puts /opt/homebrew/bin and sbin on PATH,
# which .zshrc then relies on. Nothing tool-specific belongs in this file.
# =============================================================================

# Adds /opt/homebrew/bin and /opt/homebrew/sbin to PATH, plus MANPATH/INFOPATH.
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Rust, if installed.
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# OrbStack (Docker replacement) CLI integration.
[ -f "$HOME/.orbstack/shell/init.zsh" ] && . "$HOME/.orbstack/shell/init.zsh" 2>/dev/null

true
