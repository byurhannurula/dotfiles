# =============================================================================
# .zshrc — Linux (Debian/Ubuntu)
#
# The shell core is in zshrc.common (install it to ~/.zshrc.common). This
# file holds only what is Linux-specific: clipboard shims and the Debian
# binary renames.
# =============================================================================

# ---- shared core ------------------------------------------------------------
[ -f "$HOME/.zshrc.common" ] && . "$HOME/.zshrc.common"

# ---- PATH -------------------------------------------------------------------
typeset -U path PATH

# Without it `pnpm add -g` fails and `pnpm setup` appends its own block to
# ~/.zshrc, which the next install.sh run overwrites. Same layout as macOS.
export PNPM_HOME="$HOME/.local/share/pnpm"

path=(
  "$HOME/.local/bin"
  "$PNPM_HOME/bin"
  "$HOME/.opencode/bin"
  $path
)

# ---- macOS muscle memory ----------------------------------------------------
# Typing pbcopy/open on Linux should work rather than error.
(( $+commands[xclip] )) && {
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
}
(( $+commands[xdg-open] )) && alias open='xdg-open'

# ---- per-machine ------------------------------------------------------------
[ -f "$HOME/.zshrc.local" ] && . "$HOME/.zshrc.local"
true
