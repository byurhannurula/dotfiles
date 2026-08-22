#!/bin/bash

# =============================================================================
# macOS System Preferences Setup
# =============================================================================
# Configures macOS system preferences for development
# =============================================================================

# Load helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers.sh"

# Configure macOS system preferences
configure_macos_prefs() {
    log_section "Configuring macOS System Preferences"
    
    log_info "Configuring Finder preferences..."
    # Show hidden files in Finder
    defaults write com.apple.finder AppleShowAllFiles -bool true
    # Show file extensions in Finder
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    # Show path bar in Finder
    defaults write com.apple.finder ShowPathbar -bool true
    # Show status bar in Finder
    defaults write com.apple.finder ShowStatusBar -bool true
    # Use list view in all Finder windows by default
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    # Disable the warning when changing a file extension
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    
    log_info "Configuring security and privacy..."
    # Disable the "Are you sure you want to open this application?" dialog
    defaults write com.apple.LaunchServices LSQuarantine -bool false
    
    log_info "Configuring trackpad and keyboard..."
    # Enable tap to click for trackpad
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    # Enable three finger drag
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
    # Set fast key repeat rate (requires logout/restart)
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    # Disable press-and-hold for keys in favor of key repeat
    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
    
    log_info "Configuring menu bar and dock..."
    # Show battery percentage in menu bar
    defaults write com.apple.menuextra.battery ShowPercent -string "YES"
    # Set dock to auto-hide
    defaults write com.apple.dock autohide -bool true
    # Remove dock delay
    defaults write com.apple.dock autohide-delay -float 0
    # Set dock animation speed
    defaults write com.apple.dock autohide-time-modifier -float 0.5
    # Set smaller dock size
    defaults write com.apple.dock tilesize -int 48
    # Don't show recent applications in dock
    defaults write com.apple.dock show-recents -bool false
    
    log_info "Configuring screenshots..."
    # Save screenshots to Desktop/Screenshots
    mkdir -p "$HOME/Desktop/Screenshots"
    defaults write com.apple.screencapture location -string "$HOME/Desktop/Screenshots"
    # Save screenshots in PNG format
    defaults write com.apple.screencapture type -string "png"
    # Disable shadow in screenshots
    defaults write com.apple.screencapture disable-shadow -bool true
    
    log_info "Configuring system behavior..."
    # Disable automatic termination of inactive apps
    defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true
    # Disable the crash reporter
    defaults write com.apple.CrashReporter DialogType -string "none"
    # Reveal IP address, hostname, OS version, etc. when clicking the clock in the login window
    sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName
    
    log_info "Configuring energy saving..."
    # Enable lid wakeup
    sudo pmset -a lidwake 1
    # Restart automatically on power loss
    sudo pmset -a autorestart 1
    # Sleep the display after 15 minutes
    sudo pmset -a displaysleep 15
    # Disable machine sleep while charging
    sudo pmset -c sleep 0
    # Set machine sleep to 5 minutes on battery
    sudo pmset -b sleep 5
}

# Restart affected applications
restart_applications() {
    log_info "Restarting affected applications..."
    # Restart affected applications
    for app in "Activity Monitor" "Address Book" "Calendar" "cfprefsd" \
        "Contacts" "Dock" "Finder" "Google Chrome" "Mail" "Messages" \
        "Opera" "Photos" "Safari" "SizeUp" "Spectacle" "SystemUIServer" \
        "Terminal" "Transmission" "Tweetbot" "Twitter" "iCal"; do
        killall "${app}" &> /dev/null || true
    done
}

# Main execution
main() {
    log_section "macOS System Preferences Setup"
    
    check_macos
    ask_for_sudo
    
    configure_macos_prefs
    restart_applications
    
    log_success "macOS preferences configured successfully!"
    log_warning "Some changes require logout/restart to take effect"
    log_info "Recommended: Restart your Mac to apply all changes"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
