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

# ---- safety -----------------------------------------------------------------
# -i prompts before clobbering. Muscle memory is worth less than a lost file.
alias cp="cp -i"
alias mv="mv -i"
alias mkdir="mkdir -pv"
alias ping="ping -c 5"

# ---- modern replacements ----------------------------------------------------
# Same set on every machine. Each guarded on the binary being present.
if (( $+commands[eza] )); then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza --icons --group-directories-first -l'
  alias la='eza --icons --group-directories-first -a'
  alias l='eza --icons --group-directories-first -la'
  alias tree='eza --tree --icons'
else
  alias ll='ls -l'
  alias la='ls -a'
  alias l='ls -la'
fi

if (( $+commands[bat] )); then
  alias cat='bat --paging=never'
  alias batp='bat --paging=always'    # when you do want the pager
elif (( $+commands[batcat] )); then   # Debian/Ubuntu renames the binary
  alias cat='batcat --paging=never'
  alias batp='batcat --paging=always'
fi

(( $+commands[btop] )) && alias top='btop'
(( $+commands[rg]   )) && alias grep='rg'

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
serve() {
  local port=${1:-8000}
  if command -v npx >/dev/null 2>&1; then
    npx --yes http-server -p "$port"
  else
    python3 -m http.server "$port"
  fi
}

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
