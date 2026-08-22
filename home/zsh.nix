{ pkgs, lib, ... }:

# =============================================================================
# Translated from config/.zshrc
#
# What changed and why:
#   - oh-my-zsh + manual plugin clones -> declared plugins, pinned by flake.lock
#   - powerlevel10k                    -> starship (plain TOML, no p10k wizard)
#   - the arm64/x86 brew shellenv if-block -> handled by nix-darwin automatically
#   - NVM / PNPM_HOME / cargo env PATH juggling -> direnv per project
#
# If you want to keep p10k, see the commented block at the bottom.
# =============================================================================

{
  programs.zsh = {
    enable                     = true;
    enableCompletion           = true;
    autosuggestion.enable      = true;
    syntaxHighlighting.enable  = true;

    history = {
      size            = 50000;
      save            = 50000;
      path            = "$HOME/.zsh_history";
      ignoreDups      = true;
      ignoreAllDups   = true;
      ignoreSpace     = true;
      expireDuplicatesFirst = true;
      share           = true;
    };

    # ---- oh-my-zsh ---------------------------------------------------------
    # Kept, because your config leaned on its plugins. Now version-pinned.
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "docker"
        "npm"
        "yarn"
        "brew"
        "macos"
        "sudo"          # press ESC twice to prepend sudo -- worth having
        "extract"       # `extract file.whatever` handles any archive
      ];
      # theme left empty: starship handles the prompt
      theme = "";
    };

    shellAliases = {
      # ---- modern replacements (from your .zshrc) --------------------------
      ls    = "eza --icons --group-directories-first";
      ll    = "eza -la --icons --git --group-directories-first";
      lt    = "eza --tree --level=2 --icons";
      cat   = "bat --style=plain";
      du    = "dust";
      df    = "duf";
      ps    = "procs";
      top   = "btop";
      find  = "fd";
      grep  = "rg";

      # ---- git --------------------------------------------------------------
      gs  = "git status -sb";
      ga  = "git add";
      gc  = "git commit";
      gco = "git checkout";
      gp  = "git push";
      gl  = "git pull";
      gd  = "git diff";
      glog = "git log --oneline --graph --decorate --all";

      # ---- nix: the commands you'll actually use every day ------------------
      # replaces `update_all` from your old .zshrc
      rebuild  = "sudo darwin-rebuild switch --flake ~/dev/dotfiles";
      rbcheck  = "darwin-rebuild check --flake ~/dev/dotfiles";
      rbdiff   = "darwin-rebuild build --flake ~/dev/dotfiles && nvd diff /run/current-system result";
      update   = "nix flake update --flake ~/dev/dotfiles";
      gens     = "darwin-rebuild --list-generations";
      rollback = "sudo darwin-rebuild --rollback";
      gc-nix   = "nix-collect-garbage --delete-older-than 30d && nix store optimise";
      storesize = "du -sh /nix/store";

      # ---- misc -------------------------------------------------------------
      reload = "exec zsh";
      ip     = "curl -s ifconfig.me";
      path   = "echo $PATH | tr ':' '\\n'";
    };

    initContent = lib.mkBefore ''
      # ---- options --------------------------------------------------------
      setopt AUTO_CD              # `foo` instead of `cd foo`
      setopt EXTENDED_GLOB
      setopt NO_CASE_GLOB
      setopt INTERACTIVE_COMMENTS

      # ---- keybindings ----------------------------------------------------
      bindkey '^[[A' history-search-backward   # up-arrow = prefix search
      bindkey '^[[B' history-search-forward

      # ---- functions (ported from your .zshrc) ----------------------------
      mkcd() { mkdir -p "$1" && cd "$1"; }

      # `dev` -- jump to a project folder with fuzzy search
      dev() {
        local dir
        dir=$(fd --type d --max-depth 2 . ~/dev | fzf --height 40%) && cd "$dir"
      }

      # ---- direnv-managed project shells ----------------------------------
      # (no NVM_DIR, no PNPM_HOME, no cargo env sourcing -- direnv does it)
    '';
  };

  # ---- prompt --------------------------------------------------------------
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      command_timeout = 1000;
      format = "$directory$git_branch$git_status$nodejs$python$rust$golang$nix_shell$cmd_duration$line_break$character";

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol   = "[❯](bold red)";
      };
      directory = {
        truncation_length = 3;
        truncate_to_repo  = true;
        style = "bold cyan";
      };
      git_branch.style = "bold purple";
      git_status.style = "bold yellow";
      # Shows when you're inside a `nix develop` / direnv project shell
      nix_shell = {
        format = "[$symbol$state]($style) ";
        symbol = "❄️ ";
      };
      cmd_duration = {
        min_time = 2000;
        format = "[took $duration]($style) ";
      };
    };
  };

  # ---- the thing that replaces NVM ----------------------------------------
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;   # caches the shell so cd is instant
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [ "--height 40%" "--layout=reverse" "--border" ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.bat = {
    enable = true;
    config.theme = "TwoDark";
  };

  programs.eza = {
    enable = true;
    git = true;
    icons = "auto";
  };

  # ===========================================================================
  # Want Powerlevel10k back instead of starship? Replace programs.starship with:
  #
  #   programs.zsh.oh-my-zsh.theme = "";
  #   programs.zsh.plugins = [{
  #     name = "powerlevel10k";
  #     src  = pkgs.zsh-powerlevel10k;
  #     file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  #   }];
  #   home.file.".p10k.zsh".source = ../../capture-latest/dotfiles/.p10k.zsh;
  #
  # (capture.sh grabs your existing .p10k.zsh, so the wizard answers survive.)
  # ===========================================================================
}
