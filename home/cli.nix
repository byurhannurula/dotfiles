{ ... }:

# =============================================================================
# Smaller CLI tools that just need a few lines each.
# =============================================================================

{
  # Shell history synced + searchable across machines (ctrl-r replacement)
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync   = false;    # set true + register if you want cross-machine sync
      update_check = false;
      style       = "compact";
      inline_height = 20;
      search_mode = "fuzzy";
      filter_mode_shell_up_key_binding = "session";
    };
  };

  programs.tmux = {
    enable = true;
    prefix = "C-a";
    baseIndex = 1;
    mouse = true;
    keyMode = "vi";
    historyLimit = 50000;
    escapeTime = 10;
    terminal = "screen-256color";
    extraConfig = ''
      set -g renumber-windows on
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind r source-file ~/.config/tmux/tmux.conf \; display "reloaded"
    '';
  };

  programs.ssh = {
    enable = true;

    # NOTE: recent home-manager deprecated the top-level ssh defaults in favour
    # of an explicit "*" block. If a rebuild warns about `enableDefaultConfig`,
    # add `enableDefaultConfig = false;` here -- the "*" matchBlock below
    # already covers what the defaults used to do.

    matchBlocks = {
      "github.com" = {
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };
      "gitlab.com" = {
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };
      "*" = {
        # Reuse connections -- makes repeated git pushes much faster
        controlMaster  = "auto";
        controlPath    = "~/.ssh/master-%r@%n:%p";
        controlPersist = "10m";
        extraOptions = {
          # macOS keychain integration
          UseKeychain    = "yes";
          AddKeysToAgent = "yes";
        };
      };
    };
  };

  # Better `cat`/`less` for JSON, YAML, etc. already covered by bat in zsh.nix
  programs.jq.enable = true;

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "TTY";
      vim_keys = true;
    };
  };
}
