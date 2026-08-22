{ config, lib, ... }:

# =============================================================================
# sops-nix — encrypted secrets, safely committed to a public repo.
#
# THE PROBLEM THIS SOLVES
# The old backup-configs.sh handled SSH keys by refusing to touch them, which
# was correct but left a hole: on a new machine you still had to recreate every
# key and token by hand. This closes it.
#
# HOW IT WORKS
#   1. An age private key lives OUTSIDE this repo (1Password, or a YubiKey —
#      you have two).
#   2. secrets/secrets.yaml is encrypted TO that key and committed. Anyone can
#      read the file; nobody without the key can decrypt it.
#   3. At activation sops-nix decrypts into ~/.config/sops-nix/secrets/ with
#      mode 0600. Nothing plaintext ever enters /nix/store (world-readable).
#
# The one thing you must not lose is the age key. Everything else is in git.
# =============================================================================

let
  home = config.home.homeDirectory;
in
{
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    validateSopsFiles = false;   # file may not exist yet on a fresh clone

    age.keyFile = "${home}/Library/Application Support/sops/age/keys.txt";

    # =========================================================================
    # WHAT ACTUALLY NEEDS A SECRET
    # Derived from your capture — the tools present on this machine that hold
    # credentials. Comment out anything you don't use; each entry must have a
    # matching key in secrets.yaml or the rebuild fails.
    # =========================================================================
    secrets = {

      # ---- SSH ------------------------------------------------------------
      # capture-latest/dotfiles/ssh/PRIVATE-KEYS-TODO.txt lists what you have.
      # Public keys are committed in the clear; only these are encrypted.
      "ssh/id_ed25519" = { path = "${home}/.ssh/id_ed25519"; mode = "0600"; };
      # "ssh/id_rsa"   = { path = "${home}/.ssh/id_rsa";     mode = "0600"; };

      # ---- git forges -----------------------------------------------------
      # gh stores its token in ~/.config/gh/hosts.yml — gitignored, so on a
      # fresh machine you'd otherwise have to `gh auth login` again.
      "gh/hosts.yml" = { path = "${home}/.config/gh/hosts.yml"; mode = "0600"; };
      "tokens/github" = { };            # GITHUB_TOKEN, for scripts and CI
      # "tokens/gitlab" = { };          # you have glab installed

      # ---- npm / node -----------------------------------------------------
      # You have pnpm + npm; .npmrc holds registry auth tokens.
      "npmrc" = { path = "${home}/.npmrc"; mode = "0600"; };

      # ---- services you have CLIs for (from capture) ----------------------
      "tokens/cloudflare" = { };        # cloudflared formula
      "tokens/stripe"     = { };        # ~/.config/stripe
      "tokens/sanity"     = { };        # ~/.config/sanity
      "tokens/neon"       = { };        # ~/.config/neonctl
      "tokens/tailscale"  = { };        # Tailscale auth key (App Store app)
      # "tokens/azure"    = { };        # azure-cli — usually `az login`, no static token

      # ---- AI tooling -----------------------------------------------------
      "tokens/anthropic" = { };
      # "tokens/openai"  = { };

      # ---- optional: a whole env file -------------------------------------
      # If you'd rather keep one blob than many keys, put a dotenv-format
      # value under `envfile` in secrets.yaml and source it (see below).
      # "envfile" = { path = "${home}/.config/secrets.env"; mode = "0600"; };
    };
  };

  # ---------------------------------------------------------------------------
  # Expose tokens as env vars WITHOUT baking them into the nix store.
  #
  # Note the pattern: the decrypted FILE PATH is known at build time; the
  # VALUE is read at shell startup. The secret itself never appears in a Nix
  # expression, so it never reaches /nix/store.
  #
  # Trade-off: this reads N small files on every shell start. It's ~1ms, but
  # if you notice it, switch to the single `envfile` approach above.
  # ---------------------------------------------------------------------------
  programs.zsh.initContent = lib.mkAfter ''
    # ---- secrets (sops-nix) ---------------------------------------------
    _sec() { [ -r "$2" ] && export "$1"="$(<"$2")"; }
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList
      (name: var: ''_sec ${var} "${config.sops.secrets.${name}.path or ""}"'')
      {
        "tokens/github"     = "GITHUB_TOKEN";
        "tokens/anthropic"  = "ANTHROPIC_API_KEY";
        "tokens/cloudflare" = "CLOUDFLARE_API_TOKEN";
        "tokens/stripe"     = "STRIPE_API_KEY";
        "tokens/sanity"     = "SANITY_AUTH_TOKEN";
        "tokens/neon"       = "NEON_API_KEY";
        "tokens/tailscale"  = "TS_AUTHKEY";
      })}
    unset -f _sec

    # If you enabled the single-file variant instead:
    # [ -r "$HOME/.config/secrets.env" ] && set -a && . "$HOME/.config/secrets.env" && set +a
  '';
}
