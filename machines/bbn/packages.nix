{ pkgs, ... }:

# =============================================================================
# CLI tools — mapped from YOUR machine (capture-20260808, 38 formulae).
#
# USE CASE: this repo is a bootstrap tool. It runs on a fresh install or after
# a wipe — not continuously. So the only job is to stay current enough that
# "clone + rebuild" produces a working machine. Run ./drift.sh occasionally to
# check how stale it's got.
#
# brew name -> nixpkgs name, where they differ:
#   openssl@1.1  -> openssl_1_1   (EOL since 2023 — see note below)
#   python@3.11  -> python311
#   telnet       -> inetutils
#   poppler      -> poppler_utils (the CLI tools: pdftotext, pdfimages...)
# =============================================================================

{
  environment.systemPackages = with pkgs; [
    # ---- core (you already had these) --------------------------------------
    git
    gh
    wget
    tree
    jq
    btop
    parallel
    xmlstarlet
    shellcheck
    gitleaks              # secret scanning — pairs well with the sops setup

    # ---- build / native ----------------------------------------------------
    cmake
    argon2
    hidapi                # USB HID — for the YubiKey / hardware work
    poppler_utils         # was: poppler

    # ---- cloud & infra -----------------------------------------------------
    azure-cli
    cloudflared
    podman
    # terraform is in homebrew.nix (HashiCorp tap = BUSL-licensed build).
    # If you'd rather have the open-source fork, drop the tap and use:
    # opentofu

    # ---- media -------------------------------------------------------------
    ffmpeg
    graphicsmagick

    # ---- hardware / serial -------------------------------------------------
    minicom               # pairs with the silicon-labs-vcp-driver cask
    smartmontools
    nut                   # network UPS tools

    # ---- terminal niceties -------------------------------------------------
    mprocs                # run multiple processes in one TUI
    inetutils             # was: telnet

    # ---- nix tooling (new — not from your capture) --------------------------
    nixpkgs-fmt
    nil                   # Nix LSP, gives editor autocomplete for these files
    nix-tree              # find what's eating /nix disk space
    nvd                   # used by the `rbdiff` alias

    # ---- modern CLI you don't have yet, but the aliases in home/zsh.nix
    #      expect. Remove the aliases if you don't want these.
    ripgrep
    fd
    bat
    eza
    fzf
    zoxide
    dust
    duf
    procs
  ];

  # ===========================================================================
  # NOT carried over from your capture, and why
  # ===========================================================================
  #
  # openssl@1.1  — end-of-life since Sept 2023, no security patches. Something
  #                pulled it in as a dependency. Check with:
  #                  brew uses --installed openssl@1.1
  #                and drop it if nothing needs it.
  #
  # mole         — couldn't confirm a nixpkgs package under this name. Verify
  #                with `nix search nixpkgs mole`; if absent, add "mole" to
  #                homebrew.brews instead.
  #
  # python@3.11  — you're running system Python 3.9 as python3, with 3.11 from
  # redis          brew alongside. Both are project-level concerns. Same for
  # gradle         gradle/redis. These belong in per-project dev shells, not
  # pnpm           globally — see the direnv note below.
  #
  # cocoapods    — moved to homebrew.brews (needs real Ruby + macOS integration)
  # watchman     — moved to homebrew.brews (filesystem watching is fragile under Nix)
  # fvm          — moved to homebrew.brews (manages its own Flutter SDKs)
  #
  # ===========================================================================
  # About those 17 nvm Node versions
  # ===========================================================================
  # v8, v12, v14 x2, v15, v16 x3, v17, v18 x3, v19, v20 x2, v24 x2.
  # That's years of accumulated per-project pinning, and it's a chunk of disk
  # you're short on. The direnv approach replaces all of it:
  #
  #   # in each project:  .envrc
  #   use flake
  #
  #   # in each project:  flake.nix
  #   devShells.default = pkgs.mkShell { packages = [ pkgs.nodejs_20 ]; };
  #
  # cd in, correct Node activates; cd out, it's gone. Version pinned in git
  # rather than in your head. Old versions get garbage-collected.
  #
  # If you'd rather keep nvm for now, that's fine — it just stays outside
  # this repo, and a fresh machine won't have those 17 versions (which is
  # arguably the point).
  # ===========================================================================
}
