{ globals, ... }:

# =============================================================================
# Direct translation of scripts/setup-macos-prefs.sh
#
# Every `defaults write X Y -bool true` becomes a line here. The difference:
# nix-darwin handles cfprefsd cache invalidation and activation ordering, so
# these actually stick -- which was the part that kept failing before.
#
# To find the key for a setting nix-darwin doesn't expose:
#   diff capture-latest/defaults-all.txt <(defaults read)
# then drop it into CustomUserPreferences at the bottom.
# =============================================================================

{
  system.defaults = {

    # -------------------------------------------------------------------------
    # NSGlobalDomain -- system-wide UI and input behaviour
    # -------------------------------------------------------------------------
    NSGlobalDomain = {
      # Trackpad scroll direction.
      #   false = "natural scrolling" OFF (content moves opposite to fingers)
      #   true  = macOS default
      # You asked about this one specifically -- flip it here, rebuild, done.
      "com.apple.swipescrolldirection" = false;

      # Key repeat. Lower = faster. 2 / 15 is the fast-but-not-insane pair.
      # (was: defaults write NSGlobalDomain KeyRepeat -int 2)
      KeyRepeat        = 2;
      InitialKeyRepeat = 15;

      # Disable the accent-character popup so holding j/k repeats in vim.
      ApplePressAndHoldEnabled = false;

      AppleShowAllExtensions   = true;
      AppleInterfaceStyle      = "Dark";
      AppleICUForce24HourTime  = true;
      AppleMeasurementUnits    = "Centimeters";
      AppleMetricUnits         = 1;

      # Stop macOS "helpfully" mangling code you type into text fields
      NSAutomaticSpellingCorrectionEnabled  = false;
      NSAutomaticCapitalizationEnabled      = false;
      NSAutomaticDashSubstitutionEnabled    = false;
      NSAutomaticQuoteSubstitutionEnabled   = false;
      NSAutomaticPeriodSubstitutionEnabled  = false;

      # Expanded save/print dialogs by default
      NSNavPanelExpandedStateForSaveMode  = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint     = true;
      PMPrintingExpandedStateForPrint2    = true;

      # (was: NSDisableAutomaticTermination -bool true)
      NSDisableAutomaticTermination = true;

      # Faster window resize animations
      NSWindowResizeTime = 1.0e-3;

      # Trackpad secondary click + tap-to-click at the global level
      "com.apple.mouse.tapBehavior"    = 1;
      "com.apple.trackpad.scaling"     = 1.5;
      "com.apple.springing.enabled"    = true;
      "com.apple.springing.delay"      = 0.0;
    };

    # -------------------------------------------------------------------------
    # Dock
    # -------------------------------------------------------------------------
    dock = {
      autohide               = true;
      autohide-delay         = 0.0;   # was -float 0
      autohide-time-modifier = 0.2;   # was 0.5 -- 0.2 feels much snappier
      tilesize               = 48;
      show-recents           = false;
      mru-spaces             = false; # stop spaces reordering themselves
      minimize-to-application = true;
      show-process-indicators = true;
      orientation            = "bottom";   # or "left" / "right"

      # Hot corners: 1=disabled 2=MissionControl 4=Desktop 5=ScreenSaver
      #              10=DisplaySleep 11=Launchpad 12=NotificationCenter
      wvous-bl-corner = 1;
      wvous-br-corner = 1;
      wvous-tl-corner = 1;
      wvous-tr-corner = 1;
    };

    # -------------------------------------------------------------------------
    # Finder
    # -------------------------------------------------------------------------
    finder = {
      AppleShowAllFiles              = true;   # hidden files
      AppleShowAllExtensions         = true;
      ShowPathbar                    = true;
      ShowStatusBar                  = true;
      FXPreferredViewStyle           = "Nlsv"; # Nlsv=list clmv=column icnv=icon glyv=gallery
      FXEnableExtensionChangeWarning = false;
      FXDefaultSearchScope           = "SCcf"; # search current folder, not whole Mac
      _FXShowPosixPathInTitle        = true;
      _FXSortFoldersFirst            = true;
      QuitMenuItem                   = true;   # lets you actually quit Finder
      ShowHardDrivesOnDesktop        = false;
      ShowExternalHardDrivesOnDesktop = true;
      ShowMountedServersOnDesktop    = false;
      ShowRemovableMediaOnDesktop    = true;
    };

    # -------------------------------------------------------------------------
    # Trackpad
    # (was: two separate defaults write calls for Bluetooth + built-in)
    # -------------------------------------------------------------------------
    trackpad = {
      Clicking                = true;  # tap to click
      TrackpadThreeFingerDrag = true;
      TrackpadRightClick      = true;
      Dragging                = false;
      ActuationStrength       = 1;     # 0 = silent clicking
    };

    # -------------------------------------------------------------------------
    # Screenshots
    # -------------------------------------------------------------------------
    screencapture = {
      location       = "/Users/${globals.username}/Desktop/Screenshots";
      type           = "png";
      disable-shadow = true;
      show-thumbnail = false;
    };

    # -------------------------------------------------------------------------
    # Misc
    # -------------------------------------------------------------------------
    # No "are you sure you want to open this?" for downloaded apps
    LaunchServices.LSQuarantine = false;

    loginwindow = {
      GuestEnabled              = false;
      SHOWFULLNAME              = false;
      DisableConsoleAccess      = false;
      LoginwindowText           = "";
    };

    # Battery percentage in the menu bar
    # (replaces: defaults write com.apple.menuextra.battery ShowPercent -string YES,
    #  which stopped working in Big Sur -- it moved to Control Center)
    controlcenter.BatteryShowPercentage = true;

    menuExtraClock = {
      ShowSeconds     = false;
      ShowDayOfWeek   = true;
      ShowDate        = 1;
      Show24Hour      = true;
    };

    # Disable "smart" zoom / auto-restore where it gets in the way
    CustomUserPreferences = {
      # -- things nix-darwin has no dedicated option for --

      # (was: defaults write com.apple.CrashReporter DialogType -string "none")
      "com.apple.CrashReporter".DialogType = "none";

      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;   # no .DS_Store on network shares
        DSDontWriteUSBStores     = true;   # ...or USB drives
      };

      "com.apple.frameworks.diskimages" = {
        skip-verify        = true;
        skip-verify-locked = true;
        skip-verify-remote = true;
      };

      # Ghostty -- you moved off iTerm2, so no plist import needed.
      # Actual config is managed in home/ghostty.nix as plain text.

      "com.apple.Safari" = {
        ShowFullURLInSmartSearchField = true;
        IncludeDevelopMenu            = true;
        AutoOpenSafeDownloads         = false;
      };

      "com.apple.ActivityMonitor" = {
        OpenMainWindow    = true;
        IconType          = 5;   # CPU history in the dock icon
        SortColumn        = "CPUUsage";
        SortDirection     = 0;
      };
    };

    # System-wide (needs sudo, applies to /Library/Preferences)
    CustomSystemPreferences = {
      # (was: sudo defaults write /Library/Preferences/com.apple.loginwindow
      #        AdminHostInfo HostName)
      "com.apple.loginwindow".AdminHostInfo = "HostName";
    };
  };

  # ---------------------------------------------------------------------------
  # Keyboard remapping
  # ---------------------------------------------------------------------------
  system.keyboard = {
    enableKeyMapping      = true;
    remapCapsLockToEscape = true;
  };

  # ---------------------------------------------------------------------------
  # Power management
  # ---------------------------------------------------------------------------
  # NOTE: nix-darwin's `power.sleep` doesn't distinguish AC vs battery, but your
  # old script did (`pmset -c sleep 0` / `pmset -b sleep 5`). So the AC/battery
  # split still needs a raw pmset call -- kept here as an activation script so
  # it's at least declarative and version-controlled.
  power = {
    restartAfterPowerFailure = true;   # was: sudo pmset -a autorestart 1
    sleep.display            = 15;     # was: sudo pmset -a displaysleep 15
  };

  # NOTE: nix-darwin only runs a fixed set of activationScript names
  # (preActivation, postActivation, ...). Custom names are silently ignored,
  # so everything extra goes inside postActivation.
  system.activationScripts.postActivation.text = ''
    echo "[pmset] applying AC/battery sleep policy..."
    pmset -a lidwake 1
    pmset -c sleep 0     # never sleep while plugged in
    pmset -b sleep 5     # sleep after 5 min on battery

    echo "[dirs] ensuring screenshot folder exists..."
    mkdir -p "/Users/${globals.username}/Desktop/Screenshots"

    # Spotlight indexing off — Raycast is the launcher.
    # A fresh macOS install turns this back on, so it belongs here.
    #
    # Only acts if indexing is actually on. Running `mdutil -i off -a` when
    # it's already off just prints "unable to perform operation" per volume,
    # which looks like a failure but isn't.
    #
    # This runs as root during activation, so it has the privileges the
    # interactive command lacked.
    #
    # NOTE: with indexing off, `mas list` and `mdfind` stop working.
    # capture.sh detects App Store apps via _MASReceipt instead.
    if mdutil -s / 2>/dev/null | grep -q "Indexing enabled"; then
      echo "[spotlight] disabling indexing (Raycast is the launcher)..."
      mdutil -i off -a >/dev/null 2>&1 \
        || echo "[spotlight] could not disable — grant Terminal Full Disk Access"
    else
      echo "[spotlight] already disabled"
    fi

    # Apply defaults without a full logout where macOS allows it.
    # (Replaces the killall loop at the end of setup-macos-prefs.sh.)
    echo "[defaults] activating settings..."
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u || true
  '';
}
