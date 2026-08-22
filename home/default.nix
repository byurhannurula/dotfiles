{ pkgs, globals, ... }:

# =============================================================================
# home-manager: everything that lives in $HOME.
# This replaces config/.zshrc, config/.gitconfig, and the copy-file approach
# in backup-configs.sh. Files here are *generated*, so they can't drift.
# =============================================================================

{
  imports = [
    ./zsh.nix
    ./git.nix
    ./ghostty.nix
    ./cli.nix
    ./secrets.nix
    ./signing.nix
  ];

  home.username      = globals.username;
  home.homeDirectory = "/Users/${globals.username}";

  # Like system.stateVersion -- set once, never change.
  home.stateVersion = "25.05";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER  = "less -FR";
    LANG   = "en_US.UTF-8";

    # Stop macOS littering .DS_Store while browsing
    COPYFILE_DISABLE = "1";
  };

  # User-scoped packages (vs system-wide in machines/*/packages.nix).
  # Rule of thumb: if only you use it, put it here.
  home.packages = with pkgs; [
    neovim
    tmux
    httpie
    dust        # du, but readable
    duf         # df, but readable
    procs       # ps, but readable
    sd          # sed, but sane
    hyperfine   # benchmarking
    tokei       # count lines of code
  ];

  programs.home-manager.enable = true;
}
