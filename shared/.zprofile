# =============================================================================
# .zprofile — login shells only. Runs before .zshrc.
#
# Homebrew must be set up here: it puts /opt/homebrew/bin and sbin on PATH,
# which .zshrc then relies on. Nothing tool-specific belongs in this file.
# =============================================================================

# Adds /opt/homebrew/bin and /opt/homebrew/sbin to PATH, plus MANPATH/INFOPATH.
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# /etc/zprofile's path_helper and brew shellenv both push ahead of the node
# that .zshenv chose, so a login shell would run Homebrew's node. Put it back.
if [[ -n ${FNM_MULTISHELL_PATH-} ]]; then
  path=("$FNM_MULTISHELL_PATH/bin" $path)
elif [[ -d ${FNM_DIR:-$HOME/.local/share/fnm}/aliases/default/bin ]]; then
  path=("${FNM_DIR:-$HOME/.local/share/fnm}/aliases/default/bin" $path)
fi

# OrbStack (Docker replacement) CLI integration.
[ -f "$HOME/.orbstack/shell/init.zsh" ] && . "$HOME/.orbstack/shell/init.zsh" 2>/dev/null

true
