#!/usr/bin/env bash
#
# ssh-setup.sh — SSH key, GitHub and commit signing for this machine.
#
#   ./ssh-setup.sh               guided setup; asks before every step
#   ./ssh-setup.sh status        report only; changes nothing (the dry run)
#   ./ssh-setup.sh github        add this machine's key to GitHub
#   ./ssh-setup.sh allow [FILE]  let another machine log in here with its key
#   ./ssh-setup.sh -h            this help
#
# Also run as ./install.sh ssh, and as one of the install.sh groups.
#
# Machine values (a key not named id_ed25519, signing off) go to
# ~/.gitconfig.local, never `git config --global`: ~/.gitconfig is a link into
# this repo, so --global would write them into git and onto every machine.
#
# bash 3.2 compatible — macOS ships 3.2 and will never update it.

# "~/..." in messages is display text, never a path to expand.
# shellcheck disable=SC2088
set -uo pipefail
cd "$(dirname "$0")" || exit 1

say()  { printf '\033[0;34m→\033[0m %s\n' "$1"; }
ok()   { printf '\033[0;32m✓\033[0m %s\n' "$1"; }
warn() { printf '\033[0;33m!\033[0m %s\n' "$1"; }
fail() { printf '\033[0;31m✗\033[0m %s\n' "$1"; FAILED=1; }
step() { printf '\n\033[1m%s\033[0m\n' "$1"; }
FAILED=0

# shellcheck source=lib/log.sh
. lib/log.sh
start_log ssh-setup "$@"

case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)  OS=linux ;;
  *) echo "unsupported: $(uname -s)" >&2; exit 1 ;;
esac

SSH_DIR="$HOME/.ssh"
SSH_CFG="$SSH_DIR/config"
SIGNERS="$HOME/.config/git/allowed_signers"
LOCAL_GIT="$HOME/.gitconfig.local"
HOST=$(hostname -s 2>/dev/null || hostname)
BACKUP="$HOME/.dotfiles.backup/$(date +%Y%m%d_%H%M%S)"
KEY=""          # private key path, set by pick_key

# GitHub's published ed25519 host key fingerprint:
# docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
GITHUB_FP="SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU"

need_tty() { [ -t 0 ] || { echo "needs a terminal: every step asks first" >&2; exit 1; }; }

ask() {
  printf '  %s [y/N] ' "$1"
  read -r a
  case "$a" in [yY]*) return 0 ;; *) return 1 ;; esac
}

tilde() { printf '%s' "${1/#$HOME/~}"; }
untilde() { printf '%s' "${1/#\~/$HOME}"; }
key_body() { awk '{print $2}' "$1" 2>/dev/null; }
fingerprint() { ssh-keygen -l -f "$1" 2>/dev/null | awk '{print $2}'; }

backup() {   # copy a file into this run's backup folder before changing it
  [ -f "$1" ] || return 0
  mkdir -p "$BACKUP"
  cp -p "$1" "$BACKUP/$(basename "$1")" && printf '    backup: %s\n' "$(tilde "$BACKUP/$(basename "$1")")"
}

# Private keys that have a .pub next to them, one path per line.
list_keys() {
  for pub in "$SSH_DIR"/*.pub; do
    [ -f "$pub" ] && [ -f "${pub%.pub}" ] && printf '%s\n' "${pub%.pub}"
  done
}

copy_clip() {
  if command -v pbcopy >/dev/null 2>&1; then pbcopy < "$1"
  elif command -v wl-copy >/dev/null 2>&1; then wl-copy < "$1"
  elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard < "$1"
  else return 1
  fi
}

gh_ready() { command -v gh >/dev/null 2>&1 && gh auth status -h github.com >/dev/null 2>&1; }

# ---- 1. key -----------------------------------------------------------------
new_key() {
  local def name comment
  def=id_ed25519
  [ -e "$SSH_DIR/$def" ] && def="id_ed25519_$HOST"
  printf '  file name in ~/.ssh [%s]: ' "$def"
  read -r name
  name=${name:-$def}
  case "$name" in
    *[!A-Za-z0-9._-]*|"") fail "not a valid file name: $name"; return 1 ;;
  esac
  if [ -e "$SSH_DIR/$name" ]; then
    fail "~/.ssh/$name already exists; pick another name"
    return 1
  fi
  # Host and date, not an email: the public half ends up on GitHub.
  comment="$USER@$HOST $(date +%Y-%m-%d)"
  echo "  Use a passphrase. The agent keeps it after the first use, so you do not"
  echo "  type it on every push."
  mkdir -p "$SSH_DIR" && chmod 700 "$SSH_DIR"
  # -a 100: more KDF rounds, so a stolen key file resists passphrase guessing.
  ssh-keygen -t ed25519 -a 100 -C "$comment" -f "$SSH_DIR/$name" || { fail "ssh-keygen failed"; return 1; }
  KEY="$SSH_DIR/$name"
  ok "new key: $(tilde "$KEY")  $(fingerprint "$KEY.pub")"
}

pick_key() {
  local keys n i choice
  keys=$(list_keys)
  if [ -z "$keys" ]; then
    echo "  No SSH key on this machine."
    echo "    n) make a new key for this machine (recommended: one key per machine)"
    echo "    q) quit, and restore a key from your password manager first"
    printf '  choice [n/q]: '
    read -r choice
    case "$choice" in [nN]*) new_key; return $? ;; *) return 1 ;; esac
  fi
  echo "  Keys in ~/.ssh:"
  i=0
  while IFS= read -r k; do
    i=$((i + 1))
    printf '    %d) %-28s %s\n' "$i" "$(tilde "$k")" "$(ssh-keygen -l -f "$k.pub" 2>/dev/null | awk '{print $NF, $2}')"
  done <<EOF
$keys
EOF
  n=$i
  echo "    n) make a new key"
  printf '  use which key [1-%d/n]: ' "$n"
  read -r choice
  case "$choice" in
    [nN]*) new_key; return $? ;;
    *[!0-9]*|"") fail "no key chosen"; return 1 ;;
  esac
  [ "$choice" -ge 1 ] && [ "$choice" -le "$n" ] || { fail "no key $choice"; return 1; }
  KEY=$(printf '%s\n' "$keys" | sed -n "${choice}p")
  ok "using $(tilde "$KEY")"
}

# ---- 2. permissions and agent -----------------------------------------------
fix_perms() {
  # ssh refuses a private key that others can read, with an unhelpful error.
  chmod 700 "$SSH_DIR" 2>/dev/null
  chmod 600 "$KEY" 2>/dev/null
  chmod 644 "$KEY.pub" 2>/dev/null
  ok "permissions: ~/.ssh 700, key 600"
}

agent_add() {
  local fp
  fp=$(fingerprint "$KEY.pub")
  if ssh-add -l 2>/dev/null | grep -qF "$fp"; then
    ok "key is loaded in the agent"
    return 0
  fi
  if ! ask "Load the key into the ssh agent$([ "$OS" = macos ] && echo ' and save the passphrase in the Keychain')?"; then
    return 0
  fi
  if [ "$OS" = macos ]; then
    ssh-add --apple-use-keychain "$KEY" && ok "loaded; the passphrase is in the Keychain" || fail "ssh-add failed"
  elif [ -n "${SSH_AUTH_SOCK:-}" ]; then
    ssh-add "$KEY" && ok "loaded for this session" || fail "ssh-add failed"
  else
    warn "no ssh agent running in this session; git asks for the passphrase each time"
  fi
}

# ---- 3. ~/.ssh/config ---------------------------------------------------------
ssh_config() {
  local cur
  if [ -f "$SSH_CFG" ] && grep -qiE '^[[:space:]]*Host[[:space:]].*github\.com' "$SSH_CFG"; then
    cur=$(awk 'tolower($1)=="host" {h=($0 ~ /github\.com/)} h && tolower($1)=="identityfile" {print $2; exit}' "$SSH_CFG")
    if [ -z "$cur" ] || [ "$(untilde "$cur")" = "$KEY" ]; then
      ok "~/.ssh/config has a github.com entry"
    else
      warn "~/.ssh/config sends $(tilde "$(untilde "$cur")") to github.com, not $(tilde "$KEY")"
      warn "  edit that entry by hand if this machine should use the new key"
    fi
    return 0
  fi
  ask "Add a github.com entry to ~/.ssh/config (this key only, kept in the agent)?" || return 0
  backup "$SSH_CFG"
  {
    printf '\n# Added by dotfiles ssh-setup.sh on %s\n' "$(date +%Y-%m-%d)"
    printf 'Host github.com\n'
    printf '  User git\n'
    printf '  IdentityFile %s\n' "$(tilde "$KEY")"
    # Offer only this key: with several in the agent, ssh tries each and
    # GitHub may log you in as the wrong account.
    printf '  IdentitiesOnly yes\n'
    printf '  AddKeysToAgent yes\n'
    [ "$OS" = macos ] && printf '  UseKeychain yes\n'
  } >> "$SSH_CFG"
  chmod 600 "$SSH_CFG"
  ok "github.com entry added"
}

# ---- 4. commit signing --------------------------------------------------------
signing() {
  local pub eff email body
  pub="$KEY.pub"
  if ! ask "Sign your git commits and tags with this key?"; then
    if [ "$(git config commit.gpgsign)" = true ] && ask "Turn signing off on this machine? (with it on and no usable key, every commit fails)"; then
      git config --file "$LOCAL_GIT" commit.gpgsign false
      git config --file "$LOCAL_GIT" tag.gpgsign false
      ok "signing off in $(tilde "$LOCAL_GIT")"
    fi
    SIGN=0
    return 0
  fi
  SIGN=1

  eff=$(untilde "$(git config user.signingkey)")
  if [ "$eff" = "$pub" ]; then
    ok "git signs with $(tilde "$pub")"
  else
    # The shared .gitconfig names ~/.ssh/id_ed25519.pub; any other key is a
    # per-machine value.
    git config --file "$LOCAL_GIT" user.signingkey "$(tilde "$pub")"
    ok "git signs with $(tilde "$pub") (set in $(tilde "$LOCAL_GIT"))"
  fi
  if [ "$(git config --file "$LOCAL_GIT" commit.gpgsign 2>/dev/null)" = false ]; then
    git config --file "$LOCAL_GIT" --unset commit.gpgsign
    git config --file "$LOCAL_GIT" --unset tag.gpgsign 2>/dev/null
    ok "removed the signing-off override from $(tilde "$LOCAL_GIT")"
  fi

  # allowed_signers lets git itself check the signatures: git log
  # --show-signature, git verify-commit. GitHub does not read it.
  email=$(git config user.email)
  body=$(key_body "$pub")
  if [ -z "$email" ]; then
    fail "git has no user.email; set it in ~/.gitconfig.local, then run this again"
  elif grep -qF "$body" "$SIGNERS" 2>/dev/null; then
    ok "allowed_signers has this key"
  else
    mkdir -p "$(dirname "$SIGNERS")"
    backup "$SIGNERS"
    printf '%s namespaces="git" %s\n' "$email" "$(awk '{print $1, $2}' "$pub")" >> "$SIGNERS"
    ok "added to $(tilde "$SIGNERS") for $email"
  fi
  case "$email" in
    *@users.noreply.github.com) ;;
    *) warn "GitHub marks a commit Verified only if $email is a verified email on your account" ;;
  esac
}

# ---- 5. GitHub ----------------------------------------------------------------
on_github() {   # on_github <keys|ssh_signing_keys>
  gh api "user/$1" --jq '.[].key' 2>/dev/null | grep -qF "$(key_body "$KEY.pub")"
}

gh_add() {   # gh_add <authentication|signing>
  local list=keys
  [ "$1" = signing ] && list=ssh_signing_keys
  if on_github "$list"; then
    ok "already on GitHub as a $1 key"
    return 0
  fi
  local err
  if err=$(gh ssh-key add "$KEY.pub" --title "$HOST" --type "$1" 2>&1); then
    ok "added to GitHub as a $1 key ($HOST)"
    return 0
  fi
  case "$err" in
    *"already"*) ok "already on GitHub as a $1 key"; return 0 ;;
  esac
  warn "gh could not add the $1 key: it needs more permission"
  if ask "Run 'gh auth refresh' to grant it? (opens the browser)"; then
    # On the terminal: gh only runs its login flow when stdout is one.
    gh auth refresh -h github.com -s admin:public_key,admin:ssh_signing_key </dev/tty >/dev/tty 2>&1 \
      && gh ssh-key add "$KEY.pub" --title "$HOST" --type "$1" >/dev/null \
      && ok "added to GitHub as a $1 key ($HOST)" || fail "still could not add the $1 key"
  else
    return 1
  fi
}

github() {
  local sign=${SIGN:-0}
  ask "Add this key to GitHub?" || return 0
  if gh_ready; then
    gh_add authentication || manual_github "$sign"
    [ "$sign" -eq 1 ] && { gh_add signing || manual_github 1; }
    return 0
  fi
  manual_github "$sign"
}

manual_github() {
  local sign=$1
  echo
  if copy_clip "$KEY.pub"; then
    ok "public key copied to the clipboard"
  else
    echo "  Copy this line:"
    echo
    sed 's/^/    /' "$KEY.pub"
    echo
  fi
  echo "  On GitHub, add it as two separate keys; they are separate lists:"
  echo "    1. https://github.com/settings/ssh/new"
  echo "       Title: $HOST   Key type: Authentication Key   paste, Add SSH key"
  if [ "$sign" -eq 1 ]; then
    echo "    2. https://github.com/settings/ssh/new  (again)"
    echo "       Title: $HOST   Key type: Signing Key          paste, Add SSH key"
  fi
  if [ "$OS" = macos ] && ask "Open the page in the browser?"; then
    open "https://github.com/settings/ssh/new"
  fi
  printf '  press enter when it is added: '
  read -r _
}

# ---- 6. test -------------------------------------------------------------------
github_host_key() {
  if ssh-keygen -F github.com >/dev/null 2>&1; then
    return 0
  fi
  # Pin GitHub's key from its published fingerprint instead of trusting the
  # first answer (accept-new), which a hostile network could fake.
  local tmp fp
  tmp=$(mktemp)
  ssh-keyscan -t ed25519 github.com 2>/dev/null > "$tmp"
  fp=$(ssh-keygen -l -f "$tmp" 2>/dev/null | awk '{print $2}')
  if [ "$fp" = "$GITHUB_FP" ]; then
    mkdir -p "$SSH_DIR"
    cat "$tmp" >> "$SSH_DIR/known_hosts"
    ok "github.com host key added (fingerprint matches GitHub's published one)"
  else
    fail "github.com answered with ${fp:-nothing}, not $GITHUB_FP; not trusted"
    rm -f "$tmp"
    return 1
  fi
  rm -f "$tmp"
}

test_github() {
  github_host_key || return 1
  local out
  out=$(ssh -T -o ConnectTimeout=10 git@github.com 2>&1)
  case "$out" in
    *"successfully authenticated"*) ok "GitHub: $(printf '%s' "$out" | sed -n 's/^Hi \([^!]*\)!.*/logged in as \1/p')" ;;
    *) fail "GitHub login failed: $out" ;;
  esac
}

test_signing() {
  local tmp
  tmp=$(mktemp -d)
  # Plain commit in a throwaway repo: it uses this machine's real config,
  # which is the thing being tested.
  if git -C "$tmp" init -q && git -C "$tmp" commit -q --allow-empty -m "signing test" 2>/dev/null \
     && git -C "$tmp" verify-commit HEAD >/dev/null 2>&1; then
    ok "a test commit is signed and verifies"
  else
    fail "the test commit is not signed or does not verify: run ./ssh-setup.sh status"
  fi
  rm -rf "$tmp"
}

# ---- allow: authorized_keys -----------------------------------------------------
allow() {
  local src=${1:-} line tmp fp body opts=""
  step "Let another machine log in here over SSH"
  echo "  Paste that machine's PUBLIC key (one line from its ~/.ssh/*.pub)."
  echo "  Do this before ./install.sh harden turns password login off."
  if [ -n "$src" ]; then
    line=$(head -1 "$src")
  else
    printf '  key: '
    read -r line
  fi
  case "$line" in
    *PRIVATE*) fail "that is a PRIVATE key; it must never leave its machine"; return 1 ;;
    ssh-ed25519\ *|sk-ssh-ed25519@openssh.com\ *|ecdsa-sha2-*\ *|sk-ecdsa-*\ *) ;;
    ssh-rsa\ *) warn "an RSA key; ed25519 is preferred" ;;
    *) fail "not an SSH public key"; return 1 ;;
  esac
  tmp=$(mktemp)
  printf '%s\n' "$line" > "$tmp"
  fp=$(fingerprint "$tmp")
  rm -f "$tmp"
  [ -n "$fp" ] || { fail "ssh-keygen cannot read that key"; return 1; }
  body=$(printf '%s' "$line" | awk '{print $2}')
  if grep -qF "$body" "$SSH_DIR/authorized_keys" 2>/dev/null; then
    ok "already allowed: $fp"
    return 0
  fi
  echo "  key: $fp  $(printf '%s' "$line" | cut -d' ' -f3-)"
  # 100.64.0.0/10 and fd7a:115c:a1e0::/48 are the addresses Tailscale gives
  # out. With this, the key works over the tailnet and nowhere else, so it is
  # useless on the office or cafe network even if it leaks.
  if ask "Allow this key only over Tailscale (100.x addresses)? (recommended)"; then
    opts='from="100.64.0.0/10,fd7a:115c:a1e0::/48",'
  fi
  # No agent or X11 forwarding: a session here cannot use the other machine's
  # loaded keys.
  opts="${opts}no-agent-forwarding,no-X11-forwarding"
  ask "Add it to ~/.ssh/authorized_keys?" || return 0
  mkdir -p "$SSH_DIR" && chmod 700 "$SSH_DIR"
  backup "$SSH_DIR/authorized_keys"
  printf '%s %s\n' "$opts" "$line" >> "$SSH_DIR/authorized_keys"
  chmod 600 "$SSH_DIR/authorized_keys"
  ok "allowed: $fp"
  echo "  Test from the other machine: ssh $USER@$HOST"
  [ "$OS" = macos ] && echo "  Remote Login must be on: System Settings > General > Sharing."
}

# ---- status ----------------------------------------------------------------------
status() {
  local keys k mode signkey email body n restricted out
  step "Keys"
  keys=$(list_keys)
  if [ -z "$keys" ]; then
    printf '  \033[0;31m✗\033[0m no key in ~/.ssh: ./ssh-setup.sh\n'
  else
    while IFS= read -r k; do
      if [ "$OS" = macos ]; then mode=$(stat -f %Lp "$k"); else mode=$(stat -c %a "$k"); fi
      printf '  %-30s %s  mode %s%s\n' "$(tilde "$k")" "$(ssh-keygen -l -f "$k.pub" 2>/dev/null | awk '{print $NF, $2}')" \
        "$mode" "$([ "$mode" = 600 ] || echo '  (should be 600)')"
    done <<EOF
$keys
EOF
  fi
  n=$(ssh-add -l 2>/dev/null | grep -c SHA256)
  printf '  %-30s %s\n' "loaded in agent" "$n"
  if [ -f "$SSH_CFG" ] && grep -qiE '^[[:space:]]*Host[[:space:]].*github\.com' "$SSH_CFG"; then
    printf '  %-30s %s\n' "~/.ssh/config github.com" "yes"
  else
    printf '  %-30s %s\n' "~/.ssh/config github.com" "no entry (ssh uses the default keys)"
  fi

  step "Signing"
  printf '  %-30s %s\n' "commit.gpgsign" "$(git config commit.gpgsign || echo unset)"
  signkey=$(untilde "$(git config user.signingkey)")
  if [ -z "$signkey" ]; then
    printf '  %-30s %s\n' "signing key" "unset"
  elif [ -f "$signkey" ]; then
    printf '  %-30s %s\n' "signing key" "$(tilde "$signkey")"
    body=$(key_body "$signkey")
    grep -qF "$body" "$SIGNERS" 2>/dev/null \
      && printf '  %-30s %s\n' "allowed_signers" "has it" \
      || printf '  \033[0;33m~\033[0m %-28s %s\n' "allowed_signers" "missing it: ./ssh-setup.sh"
  else
    printf '  \033[0;31m✗\033[0m %-28s %s\n' "signing key" "$(tilde "$signkey") does not exist: every commit fails"
  fi
  email=$(git config user.email)
  printf '  %-30s %s\n' "user.email" "${email:-unset}"

  step "GitHub"
  if ssh-keygen -F github.com >/dev/null 2>&1; then
    out=$(ssh -T -o ConnectTimeout=10 -o BatchMode=yes git@github.com 2>&1)
    case "$out" in
      *"successfully authenticated"*) printf '  %-30s %s\n' "login" "$(printf '%s' "$out" | sed -n 's/^Hi \([^!]*\)!.*/ok, as \1/p')" ;;
      *) printf '  \033[0;33m~\033[0m %-28s %s\n' "login" "failed (locked key or not on GitHub)" ;;
    esac
  else
    printf '  %-30s %s\n' "login" "github.com not in known_hosts yet"
  fi

  step "Who can log in here"
  if [ -s "$SSH_DIR/authorized_keys" ]; then
    n=$(grep -cvE '^[[:space:]]*(#|$)' "$SSH_DIR/authorized_keys")
    restricted=$(grep -c 'from="100.64.0.0/10' "$SSH_DIR/authorized_keys")
    printf '  %-30s %s\n' "authorized_keys" "$n keys, $restricted Tailscale-only"
  else
    printf '  %-30s %s\n' "authorized_keys" "none (no SSH login with a key)"
  fi
}

# ---- main --------------------------------------------------------------------------
usage() { sed -n '3,9p' "$0" | sed 's/^# \{0,1\}//'; }

guided() {
  need_tty
  command -v ssh-keygen >/dev/null 2>&1 || { fail "ssh-keygen not found"; exit 1; }
  echo "SSH setup for $HOST. Each step asks first; the answer is no unless you type y."

  step "1/5  Key"
  pick_key || { warn "stopped: no key"; exit 1; }
  fix_perms
  agent_add

  step "2/5  ~/.ssh/config"
  ssh_config

  step "3/5  Commit signing"
  signing

  step "4/5  GitHub"
  github

  step "5/5  Test"
  if ask "Test the GitHub login$([ "${SIGN:-0}" -eq 1 ] && echo ' and a signed commit')?"; then
    test_github
    [ "${SIGN:-0}" -eq 1 ] && test_signing
  fi

  echo
  [ -d "$BACKUP" ] && say "replaced files backed up to $(tilde "$BACKUP")"
  say "to let another machine log in here: ./ssh-setup.sh allow"
  [ "$FAILED" -eq 0 ] && ok "done" || fail "finished with failures; see above"
}

case "${1:-}" in
  "")         guided ;;
  status|--dry) status ;;
  github)     need_tty; pick_key && { SIGN=0; ask "Also as a signing key?" && SIGN=1; github; } ;;
  allow)      need_tty; allow "${2:-}" ;;
  -h|--help)  usage ;;
  *)          usage; exit 1 ;;
esac
exit "$FAILED"
