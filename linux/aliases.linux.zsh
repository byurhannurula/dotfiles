# =============================================================================
# Linux-only aliases. Install to ~/.oh-my-zsh/custom/ alongside aliases.zsh.
# =============================================================================

# apt housekeeping
alias upall="sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y"
alias aptin="sudo apt install -y"
alias aptse="apt search"

# systemd
alias sc="systemctl"
alias scu="systemctl --user"
alias jc="journalctl -xe"

# the always-on box: what is it doing
alias ports="ss -tulpn"

# Kill whatever holds a port.  killport 3000
killport() {
  local pids
  pids=$(ss -tulpnH "sport = :$1" 2>/dev/null | grep -oP 'pid=\K[0-9]+' | sort -u)
  if [ -z "$pids" ]; then
    print "nothing listening on $1"
    return 1
  fi
  print "killing: $(echo "$pids" | tr '\n' ' ')"
  echo "$pids" | xargs sudo kill -9
}

alias myip='curl -s https://ifconfig.me && echo'
alias localip="hostname -I | awk '{print \$1}'"
alias o='xdg-open .' 
alias temps="sensors 2>/dev/null || echo 'lm-sensors not installed'"
