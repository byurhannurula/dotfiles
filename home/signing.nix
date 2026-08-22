{ config, lib, pkgs, globals, ... }:

# =============================================================================
# Commit signing — SSH-based, not GPG.
#
# WHY SSH AND NOT GPG
# GPG works, but means a keyring, expiry dates, subkeys, `gpg-agent` fighting
# `ssh-agent`, and a pinentry that breaks every macOS update. SSH signing
# (git 2.34+, GitHub-supported since 2022) reuses machinery you already have
# and is about ten lines of config.
#
# THREE TIERS — same git config, different key source.
# Set `method` below. You can move up the ladder at any time; only the key
# changes, everything else stays.
#
#   "file"      private key on disk (~/.ssh/id_ed25519), encrypted in sops.
#               Simplest. Key can be copied if your Mac is compromised.
#
#   "secretive" key generated INSIDE the Secure Enclave. Cannot be exported —
#               not by you, not by malware. Every signature needs Touch ID.
#               This is the "touchid" option, and the sweet spot for a laptop.
#
#   "yubikey"   FIDO2 resident key on the YubiKey. Needs the physical token
#               present and a touch. Portable across machines. Strongest, and
#               you already own two (Yubico Authenticator + Manager are in
#               your app list).
#
# Whichever you pick, the PUBLIC key must be added to GitHub as a *signing*
# key — that's a separate list from authentication keys, and a common trip-up:
#   https://github.com/settings/keys  →  "New SSH key"  →  Key type: Signing
# =============================================================================

let
  # ---- PICK ONE ------------------------------------------------------------
  method = "file";     # "file" | "secretive" | "yubikey"
  # --------------------------------------------------------------------------

  home = config.home.homeDirectory;

  # Secretive exposes its own SSH agent socket
  secretiveSocket =
    "${home}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";

  # The signing key reference git will use.
  #
  # For agent-held keys (Secure Enclave, YubiKey) the private half never
  # touches disk, so git can't point at a file. The `key::` prefix tells git
  # "here is the literal public key, find its private half via the agent".
  signingKey = {
    file      = "${home}/.ssh/id_ed25519.pub";
    secretive = "key::${builtins.readFile ./keys/secretive.pub}";
    yubikey   = "${home}/.ssh/id_ed25519_sk.pub";
  }.${method};
in
{
  programs.git = {
    signing = {
      key = signingKey;
      signByDefault = true;      # every commit, not just when you remember
      format = "ssh";
    };

    extraConfig = {
      # Sign annotated tags too — releases are worth as much as commits
      tag.gpgSign = true;

      gpg.ssh = {
        # Lets `git log --show-signature` verify locally instead of printing
        # "no principal matched". Public data — safe to commit.
        allowedSignersFile = "${home}/.config/git/allowed_signers";
      }
      # Agent-held keys need ssh-keygen to talk to the right agent
      // lib.optionalAttrs (method == "secretive") {
        program = "${pkgs.openssh}/bin/ssh-keygen";
      };
    };
  };

  # ---------------------------------------------------------------------------
  # allowed_signers — maps identities to public keys, for local verification.
  #
  # Generated, so it can't drift from the keys below. Add collaborators here if
  # you want to verify their commits too.
  # ---------------------------------------------------------------------------
  xdg.configFile."git/allowed_signers".text =
    let
      keys = builtins.filter (k: k != "") [
        # Paste your PUBLIC keys here — capture.sh collects them into
        # capture-latest/dotfiles/ssh/*.pub
        # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... byrhn@bbn"
      ];
    in
    lib.concatMapStringsSep "\n"
      (k: ''${globals.email} namespaces="git" ${k}'')
      keys + "\n";

  # ---------------------------------------------------------------------------
  # Agent wiring for the two hardware options
  # ---------------------------------------------------------------------------
  programs.ssh.matchBlocks = lib.mkIf (method == "secretive") {
    "*".extraOptions.IdentityAgent = ''"${secretiveSocket}"'';
  };

  home.sessionVariables = lib.mkIf (method == "secretive") {
    SSH_AUTH_SOCK = secretiveSocket;
  };

  # ---------------------------------------------------------------------------
  # SETUP, per method
  # ---------------------------------------------------------------------------
  #
  # ── "file" ────────────────────────────────────────────────────────────────
  #   Uses the key sops already restores. Nothing to generate.
  #   Add ~/.ssh/id_ed25519.pub to GitHub as a SIGNING key.
  #
  # ── "secretive" ───────────────────────────────────────────────────────────
  #   1. The `secretive` cask is in homebrew.nix. Launch it once.
  #   2. Secretive → "+" → name it "git signing" →
  #        [x] Require authentication before use   (this is the Touch ID part)
  #   3. Copy the public key it shows, save it to home/keys/secretive.pub
  #      and add the same string to `keys` above.
  #   4. Add it to GitHub as a SIGNING key.
  #   5. Switch `method` to "secretive", then: make rebuild
  #
  #   Every `git commit` now prompts for Touch ID. The private key physically
  #   cannot leave the Secure Enclave.
  #
  # ── "yubikey" ─────────────────────────────────────────────────────────────
  #   ssh-keygen -t ed25519-sk \
  #     -O resident \                  # stored ON the key, portable
  #     -O application=ssh:git \
  #     -O verify-required \           # requires touch + PIN
  #     -C "byrhn@bbn git signing" \
  #     -f ~/.ssh/id_ed25519_sk
  #
  #   `-O resident` means you can recover it on any machine with:
  #     ssh-keygen -K
  #
  #   Add ~/.ssh/id_ed25519_sk.pub to GitHub as a SIGNING key, put the private
  #   handle into sops (it's a handle, not a key — but still not public), set
  #   `method = "yubikey"`, rebuild.
  #
  #   With two YubiKeys, repeat on the second and add BOTH public keys to
  #   `keys` above and to GitHub. Losing one then isn't a lockout.
  #
  # ---------------------------------------------------------------------------
  # VERIFY
  #   git commit --allow-empty -m "test: signing"
  #   git log --show-signature -1        # expect "Good signature"
  #   git push && check for "Verified" on GitHub
  #
  # If GitHub shows "Unverified": the key is registered as an authentication
  # key, not a signing key. They're separate lists.
  # ---------------------------------------------------------------------------
}
