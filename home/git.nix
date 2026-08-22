{ pkgs, globals, ... }:

# =============================================================================
# Translated from config/.gitconfig and config/.gitignore-global
# =============================================================================

{
  programs.git = {
    enable    = true;
    userName  = globals.fullName;
    userEmail = globals.email;

    aliases = {
      st   = "status -sb";
      co   = "checkout";
      br   = "branch";
      ci   = "commit";
      unstage = "reset HEAD --";
      last = "log -1 HEAD --stat";
      lg   = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      amend = "commit --amend --no-edit";
      wip  = "commit -am 'wip' --no-verify";
      undo = "reset --soft HEAD~1";
      # Which branches are already merged and safe to delete
      cleanup = "!git branch --merged | grep -v '\\*\\|main\\|master' | xargs -n 1 git branch -d";
    };

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase        = true;
      push.autoSetupRemote = true;
      push.default       = "current";
      fetch.prune        = true;
      rebase.autoStash   = true;
      merge.conflictstyle = "zdiff3";
      diff.algorithm     = "histogram";
      diff.colorMoved    = "default";
      rerere.enabled     = true;      # remember conflict resolutions

      # macOS keychain, as in your original .gitconfig
      credential.helper  = "osxkeychain";

      # URL shortcuts from your config
      "url \"git@github.com:\"".insteadOf = "gh:";
      "url \"git@gitlab.com:\"".insteadOf = "gl:";

      core = {
        editor        = "nvim";
        excludesfile  = "~/.config/git/ignore";
        pager         = "delta";
      };

      # Nicer diffs
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate    = true;
        line-numbers = true;
        side-by-side = false;
      };
    };

    # Replaces config/.gitignore-global -- generated, not copied
    ignores = [
      # macOS
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"
      "._*"
      ".Spotlight-V100"
      ".Trashes"

      # Editors
      ".vscode/"
      ".idea/"
      "*.swp"
      "*.swo"
      "*~"
      ".zed/"

      # Environments & secrets
      ".env"
      ".env.local"
      ".env.*.local"
      "*.pem"
      "*.key"

      # Dependencies & build output
      "node_modules/"
      "dist/"
      "build/"
      ".next/"
      ".turbo/"
      "__pycache__/"
      "*.pyc"
      ".venv/"
      "venv/"
      "target/"

      # Nix / direnv
      "result"
      "result-*"
      ".direnv/"

      # Logs
      "*.log"
      "npm-debug.log*"
      "yarn-error.log*"
    ];
  };

  programs.git.delta.enable = true;

  # GitHub CLI, configured declaratively
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      aliases = {
        pv = "pr view";
        pc = "pr create";
        rw = "repo view --web";
      };
    };
  };

  programs.lazygit.enable = true;
}
