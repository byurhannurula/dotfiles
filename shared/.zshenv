# =============================================================================
# .zshenv — read by EVERY zsh, including non-interactive and non-login.
#
# This is the only startup file that cron jobs, git hooks, CI runners, editor
# tasks and `zsh -c` ever see. .zshrc is interactive-only and .zprofile is
# login-only, so anything that must work in a script belongs here.
#
# Keep it small: it runs on every single shell invocation.
# =============================================================================

# ---- node -------------------------------------------------------------------
# The lazy nvm loader in zshrc.common defines node/npm/npx as shell functions.
# Functions are invisible to anything doing a raw PATH lookup, which breaks two
# things a stub cannot reach:
#
#   1. Non-interactive shells never read .zshrc, so `zsh -c 'node …'` fails
#      outright — cron, git hooks, CI, agent shells.
#   2. `#!/usr/bin/env node` shebangs. env searches PATH and cannot see a
#      function, so Homebrew's pnpm dies with "env: node: No such file".
#
# Putting the default version's bin on PATH here fixes both. Interactive shells
# still get the stubs from .zshrc, which override this and keep .nvmrc
# switching working.
#
# The version is read from nvm's own default alias so `nvm alias default 20`
# takes effect everywhere without editing this file. The alias holds a partial
# version ("24.15"), hence the glob to resolve it to a real directory.
#
# Appended, not prepended: nvm ships a corepack pnpm, and Homebrew ships its
# own. Putting nvm last lets brew's win wherever brew is on PATH, so scripts
# and terminals run the same pnpm instead of two different versions.
export NVM_DIR="$HOME/.nvm"
if [ -r "$NVM_DIR/alias/default" ]; then
  read -r _nvm_default < "$NVM_DIR/alias/default"
  for _nvm_bin in "$NVM_DIR/versions/node/v${_nvm_default}"*/bin(N); do
    [ -d "$_nvm_bin" ] && PATH="$PATH:$_nvm_bin" && break
  done
  unset _nvm_default _nvm_bin
fi

# ---- rust -------------------------------------------------------------------
# Also needed by non-interactive shells: cargo-installed binaries on PATH.
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
