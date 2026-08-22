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

path=(
  "$HOME/.local/bin"
  "$HOME/.opencode/bin"
  $path
  ./node_modules/.bin
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
