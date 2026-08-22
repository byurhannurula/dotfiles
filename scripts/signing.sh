#!/usr/bin/env bash
# =============================================================================
# signing.sh — set up / verify SSH commit signing
# =============================================================================
#   ./scripts/signing.sh init       turn signing ON NOW with an existing key
#   ./scripts/signing.sh status     what's configured, does it work
#   ./scripts/signing.sh keys       list signing-capable public keys found
#   ./scripts/signing.sh yubikey    generate a resident FIDO2 key on a YubiKey
#   ./scripts/signing.sh test       make a signed empty commit and verify it
#
# `init` works standalone — no Nix, no rebuild. It writes plain
# `git config --global` settings. The Nix module (home/signing.nix) later
# reproduces the identical config, so this is not throwaway work.
# =============================================================================

set -uo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

b()    { printf '\n\033[1;36m▸ %s\033[0m\n' "$1"; }
ok()   { printf '\033[0;32m✓\033[0m %s\n' "$1"; }
warn() { printf '\033[0;33m!\033[0m %s\n' "$1"; }
bad()  { printf '\033[0;31m✗\033[0m %s\n' "$1"; }

SECRETIVE_SOCK="$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"

cmd_init() {
  b "Enabling SSH commit signing (no Nix required)"

  # ---- 1. git version ------------------------------------------------------
  V=$(git --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
  if [ "$(printf '%s\n2.34\n' "$V" | sort -V | head -1)" != "2.34" ]; then
    bad "git $V is too old — SSH signing needs 2.34+.  brew install git"
    exit 1
  fi
  ok "git $V"

  # ---- 2. pick a key -------------------------------------------------------
  # NOTE: not `mapfile` — macOS ships bash 3.2, which doesn't have it.
  PUBS=()
  while IFS= read -r _l; do PUBS+=("$_l"); done \
    < <(find "$HOME/.ssh" -maxdepth 1 -name '*.pub' 2>/dev/null | sort)
  if [ "${#PUBS[@]}" -eq 0 ]; then
    bad "no public keys in ~/.ssh"
    echo "  generate one:  ssh-keygen -t ed25519 -C \"$(git config --get user.email)\""
    exit 1
  fi

  if [ "${#PUBS[@]}" -eq 1 ]; then
    KEY="${PUBS[0]}"
    ok "using $(basename "$KEY")"
  else
    echo
    echo "  Which key should sign your commits?"
    for i in "${!PUBS[@]}"; do
      printf '    %d) %-24s %s\n' "$((i+1))" "$(basename "${PUBS[$i]}")" \
        "$(awk '{print $1}' "${PUBS[$i]}")"
    done
    echo
    read -rp "  number: " n
    KEY="${PUBS[$((n-1))]}"
    [ -f "$KEY" ] || { bad "invalid choice"; exit 1; }
  fi

  PRIV="${KEY%.pub}"
  [ -f "$PRIV" ] || warn "private half not found at $PRIV — signing will need an agent"

  # ---- 3. identity ---------------------------------------------------------
  EMAIL=$(git config --global --get user.email || true)
  if [ -z "$EMAIL" ]; then
    read -rp "  git email: " EMAIL
    git config --global user.email "$EMAIL"
  fi
  NAME=$(git config --global --get user.name || true)
  if [ -z "$NAME" ]; then
    read -rp "  git name: " NAME
    git config --global user.name "$NAME"
  fi
  ok "identity: $NAME <$EMAIL>"

  # ---- 4. the actual config ------------------------------------------------
  b "Writing git config"
  git config --global gpg.format ssh
  git config --global user.signingkey "$KEY"
  git config --global commit.gpgsign true
  git config --global tag.gpgsign true

  AS="$HOME/.config/git/allowed_signers"
  mkdir -p "$(dirname "$AS")"
  ENTRY="$EMAIL namespaces=\"git\" $(cat "$KEY")"
  if [ -f "$AS" ] && grep -qF "$(awk '{print $2" "$3}' "$KEY")" "$AS" 2>/dev/null; then
    ok "allowed_signers already has this key"
  else
    echo "$ENTRY" >> "$AS"
    ok "added to allowed_signers"
  fi
  git config --global gpg.ssh.allowedSignersFile "$AS"

  for k in gpg.format user.signingkey commit.gpgsign tag.gpgsign gpg.ssh.allowedSignersFile; do
    printf '  %-32s %s\n' "$k" "$(git config --global --get "$k")"
  done

  # ---- 5. the GitHub step --------------------------------------------------
  b "ONE MANUAL STEP — this is where everyone gets stuck"
  cat <<EOF

  Your key is already on GitHub as an AUTHENTICATION key. That is a
  DIFFERENT list from signing keys, and auth keys do NOT verify commits.

  Add the SAME key a second time, as a signing key:

    1. https://github.com/settings/ssh/new
    2. Title:     $(basename "$PRIV") (signing)
    3. Key type:  Signing Key        <-- the dropdown, not the default
    4. Key:       paste the line below

EOF
  printf '\033[1m%s\033[0m\n\n' "$(cat "$KEY")"

  if command -v pbcopy &>/dev/null; then
    pbcopy < "$KEY" && ok "copied to clipboard"
  fi

  if command -v gh &>/dev/null && gh auth status &>/dev/null; then
    echo
    read -rp "  gh CLI is authenticated — add it automatically? [y/N] " a
    if [[ "$a" =~ ^[Yy]$ ]]; then
      gh ssh-key add "$KEY" --type signing --title "$(basename "$PRIV") (signing)" \
        && ok "registered with GitHub as a signing key" \
        || warn "failed — add it manually with the steps above"
    fi
  fi

  b "Then verify"
  echo "  ./scripts/signing.sh test"
  echo
  warn "Note: after your first 'make rebuild', home-manager takes over"
  warn "  ~/.config/git/config and reproduces these exact settings."
  warn "  Set the same key in home/signing.nix so nothing regresses."
}

cmd_status() {
  b "git config"
  for k in gpg.format user.signingkey commit.gpgsign tag.gpgsign gpg.ssh.allowedSignersFile; do
    v=$(git config --get "$k" 2>/dev/null)
    if [ -n "$v" ]; then printf '  %-32s %s\n' "$k" "${v:0:60}"
    else warn "$(printf '%-32s (unset)' "$k")"; fi
  done

  b "git version"
  V=$(git --version | grep -oE '[0-9]+\.[0-9]+')
  if [ "$(printf '%s\n2.34\n' "$V" | sort -V | head -1)" = "2.34" ]; then
    ok "git $V supports SSH signing"
  else
    bad "git $V is too old — SSH signing needs 2.34+"
  fi

  b "agents"
  if [ -S "$SECRETIVE_SOCK" ]; then ok "Secretive agent running (Secure Enclave available)"
  else warn "Secretive not running — install the cask and launch it once"; fi
  [ -n "${SSH_AUTH_SOCK:-}" ] && printf '  SSH_AUTH_SOCK = %s\n' "$SSH_AUTH_SOCK"
  ssh-add -l 2>/dev/null | sed 's/^/    /' || warn "no keys loaded in the agent"

  b "allowed_signers"
  AS="$HOME/.config/git/allowed_signers"
  if [ -s "$AS" ]; then ok "$(grep -c . "$AS") entries"; sed 's/^/    /' "$AS"
  else warn "empty or missing — local verification will say 'no principal matched'"
       warn "  add your public keys to the 'keys' list in home/signing.nix"; fi
}

cmd_keys() {
  b "Public keys on disk"
  for p in "$HOME"/.ssh/*.pub; do
    [ -e "$p" ] || continue
    t=$(awk '{print $1}' "$p")
    case "$t" in
      *-sk*|*sk-ssh*) note="FIDO2 / YubiKey — touch required" ;;
      ssh-ed25519)    note="ed25519" ;;
      ssh-rsa)        note="RSA (prefer ed25519)" ;;
      *)              note="$t" ;;
    esac
    printf '  %-34s %s\n' "$(basename "$p")" "$note"
    printf '    %s\n' "$(cat "$p")"
  done

  if [ -S "$SECRETIVE_SOCK" ]; then
    b "Secure Enclave keys (via Secretive)"
    SSH_AUTH_SOCK="$SECRETIVE_SOCK" ssh-add -L 2>/dev/null | sed 's/^/    /' \
      || warn "none — create one in the Secretive app"
    echo
    echo "  To use one for signing, put it in home/keys/secretive.pub:"
    echo "    SSH_AUTH_SOCK=$SECRETIVE_SOCK ssh-add -L | head -1 > home/keys/secretive.pub"
  fi

  b "Reminder"
  echo "  GitHub keeps AUTHENTICATION and SIGNING keys in separate lists."
  echo "  https://github.com/settings/keys → New SSH key → Key type: Signing"
}

cmd_yubikey() {
  b "Generating a resident FIDO2 signing key"
  echo "  Insert your YubiKey. You'll be asked to touch it, and to set/enter a PIN."
  echo
  F="$HOME/.ssh/id_ed25519_sk"
  [ -e "$F" ] && { bad "$F already exists — move it aside first"; exit 1; }

  ssh-keygen -t ed25519-sk \
    -O resident \
    -O application=ssh:git \
    -O verify-required \
    -C "$(whoami)@$(scutil --get LocalHostName) git signing" \
    -f "$F" || { bad "generation failed — is the YubiKey FIDO2-capable and unlocked?"; exit 1; }

  ok "created $F"
  echo
  echo "  Public key (add to GitHub as a SIGNING key, and to home/signing.nix):"
  echo
  sed 's/^/    /' "$F.pub"
  echo
  echo "  Because it's resident, you can recover it on any machine with:"
  echo "    ssh-keygen -K"
  echo
  echo "  Then set  method = \"yubikey\"  in home/signing.nix and: make rebuild"
  echo
  warn "Have a SECOND YubiKey? Repeat there and register both public keys."
  warn "One key + no backup = locked out if you lose it."
}

cmd_test() {
  b "Signing a test commit"
  git commit --allow-empty -m "test: verify commit signing" -q || { bad "commit failed"; exit 1; }
  echo
  if git log --show-signature -1 2>&1 | grep -qE 'Good "git" signature|Good signature'; then
    ok "signature verified locally"
  else
    warn "not verified locally — usually means allowed_signers is empty"
    git log --show-signature -1 2>&1 | head -5 | sed 's/^/    /'
  fi
  echo
  echo "  Undo the test commit:  git reset --soft HEAD~1"
  echo
  echo "  Use --soft, NOT --hard. --hard reverts every tracked file in the"
  echo "  working tree to the target commit, silently discarding uncommitted"
  echo "  edits. --soft removes only the commit and leaves your files alone."
  echo "  Or push and check for the 'Verified' badge on GitHub."
}

case "${1:-status}" in
  init)    cmd_init ;;
  status)  cmd_status ;;
  keys)    cmd_keys ;;
  yubikey) cmd_yubikey ;;
  test)    cmd_test ;;
  *) sed -n '2,12p' "$0"; exit 1 ;;
esac
echo
