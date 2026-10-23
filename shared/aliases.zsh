# =============================================================================
# aliases.zsh — shared by macOS and Linux.
#
# Install to ~/.oh-my-zsh/custom/, which oh-my-zsh auto-sources.
# Platform-specific aliases live in aliases.macos.zsh / aliases.linux.zsh.
#
# Modern replacements are GUARDED: each is only aliased if the tool is
# actually installed. An unguarded `alias ls=eza` breaks ls on any machine
# that does not have eza yet, which is most of them on day one.
# =============================================================================

# ---- basics -----------------------------------------------------------------
alias c="clear"
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias dev="cd ~/dev"
alias pn=pnpm
alias omz="cd ~/.oh-my-zsh"
alias config='$EDITOR ~/.zshrc'
alias reload="exec zsh"
alias myip='curl -s https://ifconfig.me && echo'   # same on both OSes

# ---- new names --------------------------------------------------------------
# Safe everywhere: these names do not exist as real commands.
if (( $+commands[eza] )); then
  alias ll='eza --icons --group-directories-first -l'
  alias la='eza --icons --group-directories-first -a'
  alias l='eza --icons --group-directories-first -la'
else
  alias ll='ls -l'
  alias la='ls -a'
  alias l='ls -la'
fi

bat=${commands[bat]:-${commands[batcat]}}   # Debian/Ubuntu renames it batcat
[ -n "$bat" ] && alias batp="${bat:t} --paging=always"

# ---- core commands, for a person at a terminal only -------------------------
# These change what real commands do: cp/mv prompt (and fail without a
# terminal), eza and bat reject flags like `ls -ltr` and `cat -v`. Claude
# Code copies interactive aliases into every command it runs, so they would
# break agents and pasted scripts. No grep=rg at all: rg -r means --replace,
# so `grep -r foo .` silently printed wrong output.
if [[ -t 0 && -t 1 && -z ${CLAUDECODE-}${CI-} ]]; then
  alias cp="cp -i"      # prompt before clobbering
  alias mv="mv -i"
  alias mkdir="mkdir -pv"
  alias ping="ping -c 5"
  (( $+commands[eza]  )) && alias ls='eza --icons --group-directories-first' \
                         && alias tree='eza --tree --icons'
  [ -n "$bat" ]          && alias cat="${bat:t} --paging=never"
  (( $+commands[btop] )) && alias top='btop'
fi
unset bat

# ---- git --------------------------------------------------------------------
alias gst="git status"
alias gadd="git add ."
alias gpush='git push -u origin HEAD'      # works whatever the branch is named
alias gl='git log --oneline --decorate --graph'
alias glog='git log --graph --pretty=oneline --abbrev-commit'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'
alias gic='git commit -m "Initial commit"'

alias g="git"
alias gcm="git commit -m"
alias gp="git push"
alias gpl="git pull"

# ---- claude code ------------------------------------------------------------
alias cc="claude"
alias ccs='$EDITOR ~/.claude/settings.json'
alias ccmd='$EDITOR ~/.claude/CLAUDE.md'

# ---- package managers -------------------------------------------------------
alias ni="npm install"
alias nr="npm run"
alias nt="npm test"
alias nb="npm run build"
alias pi="pnpm install"
alias pad="pnpm add"
alias ped="pnpm dev"
alias prun="pnpm run"          # not `pr` — that shadows nothing useful but reads badly
alias pt="pnpm test"
alias pb="pnpm build"

# ---- docker -----------------------------------------------------------------
alias d="docker"
alias dc="docker compose"      # v2 subcommand, not the old docker-compose binary
alias dcu="docker compose up"
alias dcd="docker compose down"
alias dps="docker ps"
alias di="docker images"

# ---- functions --------------------------------------------------------------
# Make a directory and enter it.
mkcd() { mkdir -p "$1" && cd "$1"; }

# Serve the current directory over HTTP.  serve [port]
# python3 rather than `npx --yes http-server`, which fetched whatever version
# was latest, with no prompt and no release cooldown.
serve() { python3 -m http.server "${1:-8000}"; }

# Kill processes by name.  killp node
killp() {
  local pids
  pids=$(pgrep -f "$1")
  if [ -z "$pids" ]; then
    print "no process matching: $1"
    return 1
  fi
  print "killing: $(echo $pids | tr '\n' ' ')"
  echo "$pids" | xargs kill -9
}

weather() { curl -s "wttr.in/${1:-}?format=3"; }

# ---- utilities --------------------------------------------------------------
alias gensecret="openssl rand -base64 32"
alias gensecret-hex="openssl rand -hex 32"
alias deleteDSFiles="find . -name '.DS_Store' -type f -delete"
alias pig="echo 'Pinging Google' && ping www.google.com"
