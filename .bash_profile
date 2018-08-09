# Add bin to PATH
export PATH = /usr/local/bin:$PATH

# Aliases for hiding and showing hidden files
alias showFiles = "defaults write com.apple.finder AppleShowAllFiles YES"
alias hideFiles = "defaults write com.apple.finder AppleShowAllFiles NO"

# Code launcher
code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;}