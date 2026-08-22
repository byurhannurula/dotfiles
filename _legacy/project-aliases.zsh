# =============================================================================
# Project-specific aliases — ReCheck, hammerJS, milvus.
#
# Moved out of .zshrc: these hardcode paths under ~/dev/recheck-projects and
# are useless on any machine that does not have those repos checked out. Kept
# because the directories still exist.
#
# To use:  ln -s .../\_legacy/project-aliases.zsh ~/.oh-my-zsh/custom/
# =============================================================================

alias hammer='cd ~/dev/recheck-projects/hammerJS/'
alias lib='cd ~/dev/recheck-projects/recheck-clientjs-library/'
alias core='cd ~/dev/recheck-projects/recheck-core/ && npx nodemon node main.js'
alias coder='cd ~/dev/recheck-projects/ && code recheck.code-workspace'
alias gui='cd ~/dev/recheck-projects/recheck-gui/ && npm run dev'
alias start-core='npx nodemon node main.js'

alias pils="echo 'Pinging Local Server' && ping 10.0.20.100"
alias milvus.start="cd ~/milvus-db && ./run.sh"
alias milvus.stop="cd ~/milvus-db && sudo docker compose stop"

recheck-pull() {
  for r in hammerJS recheck-client-js recheck-docs recheck-gui; do
    ( cd ~/dev/recheck-projects/"$r" && git pull )
  done
}

# hammer: local login / exec / beta variants
hll() { node hammer -i "./test-users/user-$1-near-123.re" -p 123 login -c "$3"; }
hel() { node hammer -i "$1" -p "$2" exec "$3"; }
hlb() { node hammer -i "$1" -p "$2" -u https://beta.recheck.io login -c "$3"; }
heb() { node hammer -i "$1" -p "$2" -u https://beta.recheck.io login -c "$3"; }
