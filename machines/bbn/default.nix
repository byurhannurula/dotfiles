{ ... }:

# =============================================================================
# bbn -- primary MacBook
# This file just imports the pieces. Edit the individual files instead.
# =============================================================================

{
  imports = [
    ./packages.nix    # CLI tools from nixpkgs
    ./homebrew.nix    # GUI apps (casks) + Mac App Store
    ./macos.nix       # system.defaults -- the defaults write replacements
  ];

  networking.computerName  = "bbn";
  networking.hostName      = "bbn";
  networking.localHostName = "bbn";
}
