export TERM=xterm-256color

# THEME
ZSH_THEME="robbyrussell"

# PATH Things
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="/bin:/usr/bin:/usr/local/bin:/sbin:$HOME/bin:$PATH"

export PATH="$PATH:$HOME/bin"

## Node
export PATH="/usr/local/bin:$PATH:./node_modules/.bin";

export PATH="${PATH}:/Users/byrhn/Library/Python/3.9/bin";

## Yarn
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

## Cargo
source "$HOME/.cargo/env"

# ZSH
export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# MYSQL
export PATH=${PATH}:/usr/local/mysql/bin/

export JAVA_HOME=$(/usr/libexec/java_home -v 17) # for mobile apps
# export PATH=$PATH:/opt/gradle/gradle-7.1.1/bin # for mobile apps

# export ANDROID_SDK_ROOT=$HOME/android
export ANDROID_HOME=~/Library/Android/sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH

export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk
# export PATH=$ANDROID_SDK_ROOT/cmdline-tools/tools/bin/:$PATH
# export PATH=$ANDROID_SDK_ROOT/emulator/:$PATH
# export PATH=$ANDROID_SDK_ROOT/platform-tools/:$PATH
# export PATH=$ANDROID_SDK_ROOT/build-tools/30.0.2/:$PATH
export PATH=$ANDROID_SDK_ROOT/cmdline-tools/bin:$PATH
export PATH=$ANDROID_SDK_ROOT/emulator:$PATH
export PATH=$ANDROID_SDK_ROOT/platform-tools/:$PATH
export PATH=$ANDROID_SDK_ROOT/build-tools/30.0.2:$PATH

# export JAVA_HOME=$(/usr/libexec/java_home -v 17) # for walltid
alias j8="export JAVA_HOME=`/usr/libexec/java_home -v 1.8`; java -version"
alias j17="export JAVA_HOME=`/usr/libexec/java_home -v 17`; java -version"
alias j19="export JAVA_HOME=`/usr/libexec/java_home -v 19`; java -version"

# Plugins
plugins=(git zsh-completions zsh-autosuggestions history-substring-search)

# load plugin
source ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

cd ~/dev

# Custom Aliases
alias pn=pnpm
alias intel="arch -x86_64"
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
alias hammer='cd ~/dev/recheck-projects/hammerJS/'
alias lib='cd ~/dev/recheck-projects/recheck-clientjs-library/'
alias core='cd ~/dev/recheck-projects/recheck-core/ && npx nodemon node main.js'
alias coder='cd ~/dev/recheck-projects/ && code recheck.code-workspace'
alias gui='cd ~/dev/recheck-projects/recheck-gui/ && npm run dev'
alias start-core='npx nodemon node main.js'

alias milvus.start="cd ~/milvus-db && ./run.sh"
alias milvus.stop="~/milvus-db && sudo docker compose stop"

function recheck-pull {
  cd ~/dev/recheck-projects/hammerJS/ && git pull
  cd ~/dev/recheck-projects/recheck-client-js/ && git pull
  cd ~/dev/recheck-projects/recheck-docs/ && git pull
  cd ~/dev/recheck-projects/recheck-gui/ && git pull
}

# hammer local login
function hll { node hammer -i "./test-users/user-$1-near-123.re" -p 123 login -c "$3"; }

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

# pnpm
export PNPM_HOME="/Users/byrhn/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

# Added by Windsurf
export PATH="/Users/byrhn/.codeium/windsurf/bin:$PATH"
