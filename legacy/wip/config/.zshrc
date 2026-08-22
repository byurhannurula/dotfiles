# =============================================================================
# Modern Zsh Configuration
# =============================================================================
# Clean, organized, and efficient zsh setup for development
# Author: Byurhan Nurula
# =============================================================================

# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme - Powerlevel10k for modern, fast prompt
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins - Essential plugins for development workflow
plugins=(
    git                    # Git aliases and functions
    zsh-autosuggestions   # Fish-like autosuggestions
    zsh-syntax-highlighting # Syntax highlighting
    zsh-completions       # Additional completions
    docker                # Docker completions
    npm                   # NPM completions
    yarn                  # Yarn completions
    pnpm                  # PNPM completions
    brew                  # Homebrew completions
    macos                 # macOS specific commands
    node                  # Node.js completions
    rust                  # Rust completions
    python                # Python completions
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# =============================================================================
# Environment Variables
# =============================================================================

# Editor
export EDITOR="code"
export VISUAL="code"

# Language
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# History
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE="$HOME/.zsh_history"

# =============================================================================
# PATH Configuration
# =============================================================================

# Homebrew - Apple Silicon vs Intel
if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
else
    eval "$(/usr/local/bin/brew shellenv)"
    export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
fi

# User binaries
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# =============================================================================
# Development Tools
# =============================================================================

# Node Version Manager (NVM)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# PNPM
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Rust/Cargo
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

# Python
export PATH="$HOME/Library/Python/3.11/bin:$PATH"
export PATH="$HOME/Library/Python/3.9/bin:$PATH"

# Ruby (Homebrew)
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

# Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# =============================================================================
# Modern CLI Tool Aliases
# =============================================================================

# Better defaults for common commands
alias ls="exa --icons"
alias ll="exa -la --icons --git"
alias lt="exa --tree --icons"
alias cat="bat"
alias grep="rg"
alias find="fd"
alias top="htop"
alias du="dust"
alias df="duf"
alias ps="procs"

# =============================================================================
# System Aliases
# =============================================================================

# Quick commands
alias c="clear"
alias reload="source ~/.zshrc && echo 'Zsh config reloaded!'"
alias config="code ~/.zshrc"
alias zshconfig="code ~/.zshrc"

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias home="cd ~"
alias dev="cd ~/dev"

# File operations
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"
alias mkdir="mkdir -pv"

# System utilities
alias flushdns="sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias showfiles="defaults write com.apple.finder AppleShowAllFiles YES && killall Finder"
alias hidefiles="defaults write com.apple.finder AppleShowAllFiles NO && killall Finder"
alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"

# Network
alias myip="curl -s https://ipinfo.io/ip"
alias localip="ipconfig getifaddr en0"
alias ping="ping -c 5"

# =============================================================================
# Development Aliases
# =============================================================================

# Git shortcuts (preserved from original config)
alias g="git"
alias gst="git status"
alias gadd="git add ."
alias gaa="git add ."
alias gcm="git commit -m"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gp="git push"
alias gpl="git pull"
alias gpush="git push -u origin master"
alias gic='git commit -m "Initial commit 🚀"'
alias glog="git log --graph --pretty=oneline --abbrev-commit"
alias gd="git diff"
alias gb="git branch"

# Package managers (Node.js focus, no Python)
alias ni="npm install"
alias nid="npm install --save-dev"
alias nig="npm install -g"
alias nr="npm run"
alias ns="npm start"
alias nt="npm test"
alias nb="npm run build"

alias yi="yarn install"
alias ya="yarn add"
alias yad="yarn add --dev"
alias yr="yarn run"
alias ys="yarn start"
alias yt="yarn test"
alias yb="yarn build"

alias pi="pnpm install"
alias pa="pnpm add"
alias pad="pnpm add --save-dev"
alias pr="pnpm run"
alias pstart="pnpm start"
alias pt="pnpm test"
alias pb="pnpm build"

# Docker
alias d="docker"
alias dc="docker-compose"
alias dcu="docker-compose up"
alias dcd="docker-compose down"
alias dcb="docker-compose build"
alias dps="docker ps"
alias di="docker images"

# Database shortcuts (if using Homebrew services)
alias mysql.start="brew services start mysql"
alias mysql.stop="brew services stop mysql"
alias mysql.restart="brew services restart mysql"
alias redis.start="brew services start redis"
alias redis.stop="brew services stop redis"
alias postgres.start="brew services start postgresql"
alias postgres.stop="brew services stop postgresql"

# =============================================================================
# Custom Functions
# =============================================================================

# Git commit with message (preserved from original)
gc() {
    if [ -z "$1" ]; then
        echo "Usage: gc 'commit message'"
        return 1
    fi
    git commit -m "$1"
}

# Git checkout branch (preserved from original)
gcb() {
    if [ -z "$1" ]; then
        echo "Usage: gcb 'branch-name'"
        return 1
    fi
    git checkout -b "$1"
}

# Create directory and cd into it
mkcd() {
    if [ -z "$1" ]; then
        echo "Usage: mkcd <directory>"
        return 1
    fi
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find and kill process by name
killp() {
    if [ -z "$1" ]; then
        echo "Usage: killp <process_name>"
        return 1
    fi
    ps aux | grep "$1" | grep -v grep | awk '{print $2}' | xargs kill -9
}

# Quick server for current directory (Node.js focused, no Python)
serve() {
    local port=${1:-8000}
    if command -v npx &> /dev/null; then
        npx http-server -p "$port"
    elif command -v python3 &> /dev/null; then
        python3 -m http.server "$port"
    else
        echo "No suitable server found. Install http-server: npm install -g http-server"
    fi
}

# Weather function
weather() {
    local city=${1:-""}
    curl -s "wttr.in/$city?format=3"
}

# Update all package managers (Node.js focused)
update_all() {
    echo "🍺 Updating Homebrew..."
    brew update && brew upgrade && brew cleanup
    
    echo "📦 Updating npm packages..."
    npm update -g
    
    if command -v yarn &> /dev/null; then
        echo "🧶 Updating Yarn..."
        yarn global upgrade
    fi
    
    if command -v pnpm &> /dev/null; then
        echo "📦 Updating PNPM..."
        pnpm update -g
    fi
    
    echo "✅ All updates complete!"
}

# =============================================================================
# Development Environment
# =============================================================================

# Smart directory navigation - only cd to ~/dev if:
# 1. We're in HOME directory
# 2. Terminal was opened directly (not from VS Code or other apps)
# 3. No specific directory context
smart_dev_navigation() {
    # Check if we're in HOME and this is a new terminal session
    if [[ "$PWD" == "$HOME" ]] && [[ -z "$VSCODE_PID" ]] && [[ -z "$TERM_PROGRAM_VERSION" ]]; then
        # Only if ~/dev exists and we're not in a specific project context
        if [[ -d "$HOME/dev" ]] && [[ -z "$PROJECT_DIR" ]]; then
            cd ~/dev 2>/dev/null
            echo "📁 Navigated to ~/dev (use 'home' to go back to ~)"
        fi
    fi
}

# Call smart navigation
smart_dev_navigation

# =============================================================================
# Plugin Configuration
# =============================================================================

# Auto-suggestions styling
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,underline"
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Syntax highlighting
export ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)

# =============================================================================
# Completion Configuration
# =============================================================================

# Case-insensitive completions
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Menu selection for completions
zstyle ':completion:*' menu select

# Colorful completions
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# =============================================================================
# History Configuration
# =============================================================================

# History options
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_BEEP
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

# =============================================================================
# Final Setup
# =============================================================================

# Load any local customizations
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# Welcome message (only for interactive shells)
if [[ $- == *i* ]]; then
    echo "🚀 Welcome to your development environment!"
    echo "📁 Current directory: $(pwd)"
    if command -v node &> /dev/null; then
        echo "📦 Node.js: $(node --version)"
    fi
    if command -v git &> /dev/null; then
        echo "🔧 Git: $(git --version | cut -d' ' -f3)"
    fi
fi
