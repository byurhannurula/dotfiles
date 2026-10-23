# =============================================================================
# .zshenv — read by EVERY zsh, including non-interactive and non-login.
#
# This is the only startup file that cron jobs, git hooks, CI runners, editor
# tasks and `zsh -c` ever see. .zshrc is interactive-only and .zprofile is
# login-only, so anything that must work in a script belongs here.
#
# Keep it small: it runs on every single shell invocation.
# =============================================================================

# ---- node (fnm) --------------------------------------------------------------
# Non-interactive shells never read .zshrc, so cron, git hooks, CI, agent
# shells and `#!/usr/bin/env node` shebangs only see what is set here.
#
# fnm keeps the default version behind a stable symlink, so a plain PATH entry
# is enough: no subprocess, no version lookup. Interactive shells then run
# `fnm env` in zshrc.common, which puts the per-shell .nvmrc version first.
#
# Prepended so it beats Homebrew's `node`, which brew installs as a dependency
# of other formulae (agent-browser) and would otherwise win for every script.
#
# The fnm binary itself sits in its data dir when installed by fnm's own
# script (Linux); Homebrew puts it in /opt/homebrew/bin instead.
typeset -U path PATH     # nested shells re-read this file; keep PATH unique

# Homebrew for non-login shells (cron, hooks, GUI-launched editors), which
# never read .zprofile. Only when absent: prepending again would push brew
# ahead of a node version a parent shell already chose.
(( ${path[(Ie)/opt/homebrew/bin]} )) || [ ! -d /opt/homebrew/bin ] \
  || path=(/opt/homebrew/bin /opt/homebrew/sbin $path)

export FNM_DIR="${FNM_DIR:-$HOME/.local/share/fnm}"
[ -x "$FNM_DIR/fnm" ] && path=("$FNM_DIR" $path)

# Set by `fnm env` in a parent shell that already picked the .nvmrc version;
# the default would override it in every child `zsh -c` (npm scripts, hooks).
if [[ -z ${FNM_MULTISHELL_PATH-} && -d $FNM_DIR/aliases/default/bin ]]; then
  path=("$FNM_DIR/aliases/default/bin" $path)
fi

# ---- rust -------------------------------------------------------------------
# Also needed by non-interactive shells: cargo-installed binaries on PATH.
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
