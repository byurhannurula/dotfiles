{ pkgs, globals, system, ... }:

# =============================================================================
# Shared across every machine. Machine-specific stuff goes in machines/<host>/.
# =============================================================================

{
  nixpkgs.hostPlatform = system;
  nixpkgs.config.allowUnfree = true;   # needed for vscode, spotify, etc.

  # Don't change after first install -- it pins backwards-compat behaviour.
  system.stateVersion = 5;

  # Required for any user-scoped system.defaults to apply.
  system.primaryUser = globals.username;

  users.users.${globals.username} = {
    name = globals.username;
    home = "/Users/${globals.username}";
  };

  # ---------------------------------------------------------------------------
  # Nix daemon settings
  # ---------------------------------------------------------------------------
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" globals.username ];

      # Prebuilt binaries -- without these you compile everything from source.
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    # ---- THE DISK SPACE ANSWER ----------------------------------------------
    # Without this, /nix grows without bound. With it, steady state is ~10-20GB.
    gc = {
      automatic = true;
      interval  = { Weekday = 0; Hour = 3; Minute = 0; };  # Sundays 03:00
      options   = "--delete-older-than 30d";
    };

    # Hardlinks byte-identical files across store paths. Big win, runs nightly.
    optimise.automatic = true;
  };

  # ---------------------------------------------------------------------------
  # Fonts -- installed system-wide, available to Ghostty/VS Code immediately
  # ---------------------------------------------------------------------------
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.meslo-lg      # the one Powerlevel10k wants
  ];

  # Shells that may be set as login shells
  environment.shells = [ pkgs.zsh pkgs.bashInteractive ];
  programs.zsh.enable = true;   # sets up the system-level zsh plumbing

  # ---------------------------------------------------------------------------
  # Touch ID for sudo — borrowed from notthebee's darwin config.
  # Survives macOS updates (which normally reset /etc/pam.d/sudo).
  # You'll use `sudo darwin-rebuild` constantly; this makes it a fingerprint.
  # ---------------------------------------------------------------------------
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    reattach = true;   # keeps it working inside tmux
  };

  # Raise the open-file limit — Node/watchman/Xcode all hit the default of 256
  launchd.daemons.maxfiles = {
    serviceConfig = {
      Label = "limit.maxfiles";
      ProgramArguments = [ "launchctl" "limit" "maxfiles" "65536" "524288" ];
      RunAtLoad = true;
      ServiceIPC = false;
    };
  };

  # Show which generation you're on in the login window / `darwin-version`
  system.configurationRevision = null;
}
