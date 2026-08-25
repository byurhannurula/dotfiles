# =============================================================================
# .profile — POSIX shells (sh, bash, dash), NOT zsh.
#
# zsh ignores this file entirely; it reads .zshenv/.zprofile/.zshrc instead.
# What lands here is for the occasional `sh -l` or a Linux display manager
# that sources .profile at login.
#
# Machine-specific entries (dfx, work tools) belong in ~/.profile.local, which
# is not tracked.
# =============================================================================

# Rust, if installed.
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# User binaries. zsh gets this from .zshrc's path array instead.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) PATH="$HOME/.local/bin:$PATH" ;;
esac
export PATH

[ -f "$HOME/.profile.local" ] && . "$HOME/.profile.local"

true
