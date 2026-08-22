{ ... }:

# =============================================================================
# Ghostty
#
# This is why moving off iTerm2 was the right call: iTerm's config is a binary
# plist you can only manage by copying the whole file. Ghostty reads plain
# text, so it becomes real config -- diffable, reviewable, per-machine.
#
# NOTE: nixpkgs' `ghostty` package is Linux-only; on macOS the app comes from
# the Homebrew cask (see machines/bbn/homebrew.nix). We only manage the
# config file here, which is all we need.
# =============================================================================

{
  xdg.configFile."ghostty/config".text = ''
    # ---- font -------------------------------------------------------------
    font-family = JetBrainsMono Nerd Font
    font-size = 14
    font-thicken = true

    # ---- theme ------------------------------------------------------------
    theme = catppuccin-mocha
    background-opacity = 0.96
    background-blur-radius = 20

    # ---- window -----------------------------------------------------------
    window-padding-x = 12
    window-padding-y = 8
    window-decoration = true
    window-save-state = always
    macos-titlebar-style = tabs
    macos-option-as-alt = true

    # ---- cursor -----------------------------------------------------------
    cursor-style = block
    cursor-style-blink = false
    mouse-hide-while-typing = true

    # ---- scrollback -------------------------------------------------------
    scrollback-limit = 100000

    # ---- shell ------------------------------------------------------------
    shell-integration = zsh
    shell-integration-features = cursor,sudo,title

    # ---- keybindings ------------------------------------------------------
    keybind = cmd+d=new_split:right
    keybind = cmd+shift+d=new_split:down
    keybind = cmd+w=close_surface
    keybind = cmd+shift+enter=toggle_split_zoom
    keybind = cmd+k=clear_screen

    # ---- misc -------------------------------------------------------------
    confirm-close-surface = false
    quit-after-last-window-closed = false
    copy-on-select = clipboard
  '';
}
