# lib/log.sh — sourced by the setup scripts, not run.
#
# Copies everything a script prints to ~/.dotfiles.backup/logs/, so a run on
# another machine (the work laptop) can be read back afterwards.
#
# Questions still read from the terminal. Passphrases and the sudo password
# are typed on the terminal device, not stdout, so they never reach the log.
# A command whose OUTPUT is secret (the FileVault recovery key) must write to
# /dev/tty itself.
#
# bash 3.2 compatible.

start_log() {   # start_log <script name> [its arguments...]
  local name=$1
  shift
  LOG_DIR="$HOME/.dotfiles.backup/logs"
  mkdir -p "$LOG_DIR" 2>/dev/null || return 0
  LOG="$LOG_DIR/$name-$(date +%Y%m%d_%H%M%S).log"
  exec > >(tee -a "$LOG") 2>&1
  printf '# %s %s | %s | %s %s | %s\n' "$name" "$*" "$(date '+%Y-%m-%d %H:%M:%S')" \
    "$(uname -s)" "$(sw_vers -productVersion 2>/dev/null || uname -r)" "$(hostname -s 2>/dev/null)"
  trap 'printf "\033[0;34m→\033[0m log: %s\n" "${LOG/#$HOME/~}"' EXIT
}
