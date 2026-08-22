# =============================================================================
# .zshrc — macOS
#
# The shell core is in zshrc.common (install it to ~/.zshrc.common). This
# file holds only what is macOS-specific: the pnpm path under ~/Library and
# Homebrew keg-only formulae.
# =============================================================================

# ---- shared core ------------------------------------------------------------
[ -f "$HOME/.zshrc.common" ] && . "$HOME/.zshrc.common"

# ---- PATH -------------------------------------------------------------------
# typeset -U keeps the array de-duplicated, so re-sourcing never stacks entries.
typeset -U path PATH

export PNPM_HOME="$HOME/Library/pnpm"

path=(
  "$HOME/.local/bin"
  "$PNPM_HOME"
  "$HOME/.opencode/bin"
  /opt/homebrew/opt/ruby/bin       # keg-only: brew does not add this itself
  $path
  ./node_modules/.bin              # project-local binaries, lowest priority
)

# ---- homebrew ---------------------------------------------------------------
export HOMEBREW_NO_AUTO_UPDATE=1     # brew install should not also update
export HOMEBREW_NO_ENV_HINTS=1

# ---- per-machine ------------------------------------------------------------
# Not in git: anything true of this one Mac only.
# The trailing `true` keeps $? at 0 when the file is absent.
[ -f "$HOME/.zshrc.local" ] && . "$HOME/.zshrc.local"
true
