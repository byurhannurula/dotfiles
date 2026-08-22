export TERM=xterm-256color

# THEME
ZSH_THEME="byurhanbeyzat"

# PATH Things
export PATH=$HOME/bin:/usr/local/bin:$PATH

## Node
PATH="/usr/local/bin:$PATH:./node_modules/.bin";

## Yarn
PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# ZSH
export ZSH="/Users/byurhanbeyzat/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh

# NVM
export NVM_DIR=~/.nvm
source /usr/local/opt/nvm/nvm.sh

# MYSQL
export PATH=${PATH}:/usr/local/mysql/bin/

# ANDROID
export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk1.8.0_231.jdk/Contents/Home"
export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH="$PATH:$JAVA_HOME/bin/:$ANDROID_HOME:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/tools"

# Plugins
plugins=(git zsh-completions zsh-autosuggestions history-substring-search)

# load plugin
source ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

cd ~/dev

# Custom Aliases
alias c="clear";
alias config="code ~/.zshrc"
alias pig="echo 'Pinging Google' && ping www.google.com";
alias pils="echo 'Pinging Local Server' && ping 10.0.20.100";
alias deleteDSFiles="find . -name '.DS_Store' -type f -delete"
alias flushdns="sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder"
alias showFiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app'
alias hideFiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app'
alias upall="yarn global upgrade && npm update -g && brew doctor && brew upgrade"
##########################################################################
# Convenient MySQL CLI aliases
alias mysql.start="sudo /usr/local/mysql/support-files/mysql.server start"
alias mysql.stop="sudo /usr/local/mysql/support-files/mysql.server stop"
alias mysql.restart="sudo /usr/local/mysql/support-files/mysql.server restart"
alias mysql.status="sudo /usr/local/mysql/support-files/mysql.server status"
alias mysql="/usr/local/mysql/bin/mysql"
alias mysqldump="/usr/local/mysql/bin/mysqldump"
##########################################################################
## git aliases
alias gst="git status";
alias gadd="git add .";
alias gpush='git push -u origin master';
alias gic='git commit -m "Initial commit 🚀"';
alias glog='git log --graph --pretty=oneline --abbrev-commit';
##########################################################################
# ReCheck aliases
alias hammer='cd ~/dev/recheck/hammerJS/'
alias clientjs='cd ~/dev/recheck/recheck-client-js/'
alias docs='cd ~/dev/recheck/recheck-docs/ && npx nodemon node main.js'
alias coder='cd ~/dev/recheck/ && code recheck.code-workspace'
alias gui='cd ~/dev/recheck/recheck-gui/ && npm run dev'
alias start-docs='npx nodemon node main.js'

function recheck-pull {
  cd ~/dev/recheck/hammerJS/ && git pull
  cd ~/dev/recheck/recheck-client-js/ && git pull
  cd ~/dev/recheck/recheck-docs/ && git pull
  cd ~/dev/recheck/recheck-gui/ && git pull
}

# hammer local login
function hll { node hammer -i "$1" -p "$2" login -c "$3"; }

# hammer exec login
function hel { node hammer -i "$1" -p "$2" exec "$3"; }

# hammer login beta
function hlb { node hammer -i "$1" -p "$2" -u https://beta.recheck.io login -c "$3"; }

# hammer exec beta
function heb { node hammer -i "$1" -p "$2" -u https://beta.recheck.io login -c "$3"; }

##########################################################################
# Custom functions
function gc { git commit -m "$@"; }
function gcb { git checkout -b "$@"; }

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
