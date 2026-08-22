{ ... }:

# =============================================================================
# Homebrew — generated from capture-20260808 (your real machine), not guesswork.
#
# THE DEBLOAT LOOP
# ----------------
# This list is the definition of "clean". Anything installed but not listed
# gets removed on the next rebuild. So:
#
#   1. Install whatever you want to try:  brew install --cask some-app
#   2. Use it. Forget about it. Install ten more.
#   3. Occasionally:  ./drift.sh
#      → lists everything installed but not declared = the removal list
#   4. Anything worth keeping, add to this file.
#   5. rebuild  → everything else is gone.
#
# That's your spring clean, and it's one command.
#
# READ BEFORE ENABLING (see cleanup below):
#   - "zap" also deletes app preferences and ~/Library/Application Support
#     data for removed apps. Deeper clean, but a temporarily-unlisted app
#     loses its settings.
#   - "uninstall" removes the app but keeps its data. Safer middle ground.
#   - ALWAYS run ./drift.sh first. It prints exactly what will be removed.
# =============================================================================

{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade    = false;

      # "zap"       remove undeclared apps AND their preferences/data
      # "uninstall" remove undeclared apps, keep their data
      # "none"      never remove anything
      #
      # START AS "uninstall" for the first few rebuilds. Once you trust the
      # list, switch to "zap" for the full clean.
      #
      # NOTE: this only governs brew-managed things. Apps still sitting in
      # /Applications from drag-and-drop are invisible to it — that's why
      # adopting them (--adopt) matters before you turn this on.
      cleanup = "uninstall";
    };

    # Skip the "downloaded from the internet, are you sure?" gatekeeper prompt
    # for casks. Pairs with LaunchServices.LSQuarantine in macos.nix — without
    # this, a fresh-machine rebuild means clicking through ~40 dialogs.
    caskArgs.no_quarantine = true;

    # ---- taps ---------------------------------------------------------------
    # HOMEBREW TAP TRUST (new requirement — you hit this installing mas):
    # third-party taps are ignored until explicitly trusted. On a fresh machine
    # the rebuild will silently skip their formulae unless you run:
    #
    #   brew trust adembc/tap hashicorp/tap metafab/tap ngrok/ngrok terraform-linters/tap
    #
    # Prefer per-item trust where you only need one thing:
    #   brew trust --formula hashicorp/tap/terraform
    #   brew trust --cask ngrok/ngrok/ngrok
    #
    # Only taps you ACTUALLY use are listed below. Dropped as unused —
    # nothing installed from them (untap with `brew untap <name>`):
    #   jsattler/tap, stripe/stripe-cli, supersonic-app/supersonic,
    #   byurhannurula/tap (your own — re-add if you publish to it)
    taps = [
      "adembc/tap"               # lazyssh
      "hashicorp/tap"            # terraform
      "metafab/tap"              # otel-gui
      "ngrok/ngrok"              # ngrok cask
      "terraform-linters/tap"    # tflint
      "homebrew/services"
    ];

    # ---- formulae that must stay in Homebrew --------------------------------
    brews = [
      # Tap-qualified — these do not exist in nixpkgs under these names
      "adembc/tap/lazyssh"
      "hashicorp/tap/terraform"     # nixpkgs HAS terraform, but the HashiCorp
                                    # tap build is the licensed BUSL one; keep
                                    # here unless you want OpenTofu instead
      "metafab/tap/otel-gui"

      "mas"                         # NOT currently installed — install it and
                                    # re-run capture.sh to pick up App Store apps
                                    # (Pages, Numbers, Xcode are unmanaged now)

      # macOS-integration formulae that are painful under Nix
      "cocoapods"
      "watchman"                    # needs to watch the real FS; brew build is safer
      "fvm"                         # Flutter version manager, manages its own SDKs
    ];

    # ---- casks (your actual 17) ---------------------------------------------
    casks = [
      "android-platform-tools"
      "betterdisplay"
      "drawio"
      "flameshot"
      "iptvnator"
      "jotter"
      "monitorcontrol"
      "ngrok"
      "ollama-app"
      "silicon-labs-vcp-driver"     # USB-serial driver — pairs with minicom
      "stats"
      "tflint"

      # Java. NOTE: you have BOTH old and new naming installed:
      #   temurin8 / temurin@8   and   temurin17 / temurin@17
      # Homebrew renamed these; the unversioned duplicates are dead weight.
      # Recommend: brew uninstall --cask temurin8 temurin17
      # then keep only the @-suffixed ones below.
      "temurin"                     # current LTS (you're on openjdk 25)
      "temurin@8"
      "temurin@17"

      # =======================================================================
      # ADOPTED from drag-and-drop installs.
      #
      # These are already in /Applications but weren't managed. Hand each one
      # over to Homebrew WITHOUT reinstalling:
      #
      #   brew install --cask --adopt ghostty visual-studio-code claude ...
      #
      # (--adopt takes ownership of an existing app in place. If your brew is
      #  older and lacks it, use --force, which overwrites with a fresh copy.)
      #
      # Do this once, then a fresh machine gets all of them automatically.
      # =======================================================================

      # ---- daily drivers ----
      "ghostty"
      "brave-browser"               # your main browser
      "visual-studio-code"
      "claude"
      "raycast"
      "tableplus"
      "orbstack"

      # ---- browsers (secondary) ----
      "google-chrome"
      "firefox"

      # ---- dev ----
      "mongodb-compass"
      "cyberduck"

      # ---- comms ----
      "telegram"
      "discord"
      "viber"

      # ---- network / remote ----
      "anydesk"
      # "tailscale-app"   → App Store install, see masApps
      # "home-assistant"  → App Store install, see masApps

      # ---- hardware / making ----
      "balenaetcher"
      "bambu-studio"
      "orcaslicer"
      "raspberry-pi-imager"
      "yubico-yubikey-manager"
      # "yubico-authenticator" → App Store install, see masApps

      # Secure Enclave SSH agent — Touch ID commit signing.
      # See home/signing.nix; needed for method = "secretive".
      "secretive"

      # ---- utilities ----
      "appcleaner"
      "coconutbattery"
      "tiles"
      "superwhisper"
      "raindropio"
      # "the-unarchiver" → App Store install, see masApps
      # "hiddenbar"      → App Store install, see masApps

      # ---- media ----
      "vlc"
      "transmission"
      "calibre"
    ];

    # ---- Mac App Store ------------------------------------------------------
    # Detected via _MASReceipt (Spotlight indexing is off on this machine, so
    # `mas list` returns nothing — see capture.sh).
    #
    # Requires the `mas` formula above at restore time, and you must be signed
    # in to the App Store before a rebuild, or these are skipped.
    masApps = {
      "Xcode"                = 497799835;
      "Home Assistant"       = 1099568401;
      "Hidden Bar"           = 1452453066;
      "The Unarchiver"       = 425424353;
      "Tailscale"            = 1475387142;
      "Yubico Authenticator" = 1497506650;

      # The lookup API didn't resolve these two — the iWork bundle IDs map to
      # universal iOS/macOS entries that the macSoftware filter rejects.
      # These IDs are stable and well-known:
      "Pages"                = 409201541;
      "Numbers"              = 409203825;
    };
  };
}
