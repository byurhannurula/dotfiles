# =============================================================================
# macOS-only aliases and functions.
# Install to ~/.oh-my-zsh/custom/ alongside aliases.zsh.
# =============================================================================

# ---- ports ------------------------------------------------------------------
# macOS has no `ss`; lsof is the equivalent. -nP skips DNS and port-name
# lookups, which is what makes the plain version slow.
alias ports='sudo lsof -iTCP -sTCP:LISTEN -nP'

# What is on this port?   port 3000
port() { sudo lsof -iTCP:"$1" -sTCP:LISTEN -nP; }

# Kill whatever holds a port.  killport 3000
# The daily "address already in use" fix.
killport() {
  local pids
  pids=$(lsof -tiTCP:"$1" -sTCP:LISTEN 2>/dev/null)
  if [ -z "$pids" ]; then
    print "nothing listening on $1"
    return 1
  fi
  print "killing: $(echo "$pids" | tr '\n' ' ')"
  echo "$pids" | xargs kill -9
}

# ---- system -----------------------------------------------------------------
alias intel="arch -x86_64"                 # run a command under Rosetta
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias showFiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias hideFiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'
alias cpu='sudo powermetrics --samplers cpu_power -i1000 -n1'
alias battery='pmset -g batt'
alias wifi='networksetup -getairportnetwork en0'
alias myip='curl -s https://ifconfig.me && echo'
alias localip="ipconfig getifaddr en0"

# Keep the Mac awake until you Ctrl-C.  awake
alias awake='caffeinate -dimsu'

# ---- finder -----------------------------------------------------------------
alias o='open .'                           # current dir in Finder
alias trash='trash'                        # brew install trash — undoable rm

# ---- homebrew ---------------------------------------------------------------
alias upall="brew update && brew upgrade && brew cleanup && npm update -g"
alias bl='brew leaves'                     # what you installed on purpose
alias bo='brew outdated'

# ---- quarantine -------------------------------------------------------------
# "app is damaged and can't be opened" after downloading a signed-but-unnotarised
# binary. Strips the com.apple.quarantine attribute.
unquarantine() { sudo xattr -rd com.apple.quarantine "$@"; }

# ---- mysql ------------------------------------------------------------------
# A local /usr/local/mysql install, not the brew formula.
alias mysql="/usr/local/mysql/bin/mysql"
alias mysqldump="/usr/local/mysql/bin/mysqldump"
alias mysql.start="sudo /usr/local/mysql/support-files/mysql.server start"
alias mysql.stop="sudo /usr/local/mysql/support-files/mysql.server stop"
alias mysql.restart="sudo /usr/local/mysql/support-files/mysql.server restart"
alias mysql.status="sudo /usr/local/mysql/support-files/mysql.server status"
