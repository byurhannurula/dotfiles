# Custom Aliases
alias pn=pnpm
alias c="clear"
alias config="code ~/.zshrc"
alias pig="echo 'Pinging Google' && ping www.google.com"

alias gensecret="openssl rand -base64 32"
alias gensecret-hex="openssl rand -hex 32"

alias cc="claude"
alias ccs="code ~/.claude/settings.json"
alias ccmd="code ~/.claude/CLAUDE.md"

# --- everyday replacements (installed by module 03) -----------------------
alias ls='eza --icons --group-directories-first'
alias ll='ls -l'
alias la='ls -a'
alias l='ls -la'
alias cat='bat --paging=never'        # bat is the modern cat
alias batp='bat --paging=always'      # ...when you actually want the pager
alias diff='delta'                    # git-delta is the pager anyway
alias ..='cd ..'
alias ...='cd ../..'

##########################################################################
## git aliases
alias gst="git status"
alias gadd="git add ."
alias gpush='git push -u origin HEAD' # works whatever the branch is named
alias gic='git commit -m "Initial commit 🚀"'
alias gl='git log --oneline --decorate --graph'
alias glog='git log --graph --pretty=oneline --abbrev-commit'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'

# Custom functions
function gc { git commit -m "$@"; }
function gcb { git checkout -b "$@"; }
