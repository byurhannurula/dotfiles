# Aliases
# basic

cd ~/dev
alias c 'clear'
alias finderShowHidden='defaults write com.apple.finder ShowAllFiles TRUE'
alias finderHideHidden='defaults write com.apple.finder ShowAllFiles FALSE'


# git
alias gst='git status'
alias gp='git push -u origin master'
alias gic='git commit -m "Initial commit 🚀"'
alias glog='git log --graph --pretty=oneline --abbrev-commit'


# npm/yarn/homebrew
alias upall 'yarn global upgrade && npm update -g && brew doctor && brew upgrade'
alias hbapps "echo '- homebrew -' && brew list && echo '- homebrew cask -' && brew cask list"


# Functions
function cleandsstores
  find . -name '.DS_Store' -exec rm -f '{}' ';'
end

function cleannodemodules
  find . -name 'node_modules' -type d -prune -exec rm -rf '{}' +
end

function killport
  lsof -i :$1 | awk 'NR!=1 {print $2}' | xargs kill
end