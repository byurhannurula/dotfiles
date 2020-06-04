export TERM=xterm-256color

# THEME
ZSH_THEME="byurhanbeyzat"

# PATH Things
export PATH=$HOME/bin:/usr/local/bin:$PATH

## Node
PATH="/usr/local/bin:$PATH:./node_modules/.bin";

# ZSH
export ZSH="/Users/byurhanbeyzat/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh

plugins=(
  git
  zsh-completions
  zsh-autosuggestions
  history-substring-search
)

# load plugin
source ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Custom Aliases
alias c="clear";
alias config="sudo nano ~/.zshrc"
alias pig="echo 'Pinging Google' && ping www.google.com";


##########################################################################
# Convenient MySQL CLI aliases
alias mysql.start="sudo /usr/local/mysql/support-files/mysql.server start"
alias mysql.stop="sudo /usr/local/mysql/support-files/mysql.server stop"
alias mysql.restart="sudo /usr/local/mysql/support-files/mysql.server restart"
alias mysql.status="sudo /usr/local/mysql/support-files/mysql.server status"
alias mysql="/usr/local/mysql/bin/mysql"
alias mysqldump="/usr/local/mysql/bin/mysqldump"

## git aliases
alias gst="git status";
alias gpush='git push -u origin master';
alias gic='git commit -m "Initial commit 🚀"';
alias glog='git log --graph --pretty=oneline --abbrev-commit';

# Custom functions
function gc { 
  git commit -m "$@"; 
}
function gcb {
  git checkout -b "$@"; 
}
killport() {
  lsof -i tcp:"$*" | awk 'NR!=1 {print $2}' | xargs kill -9 ;
}

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"