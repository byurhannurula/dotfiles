#!/bin/bash

# =============================================================================
# Main Setup Script - macOS Development Environment
# =============================================================================
# Orchestrates the complete setup process using modular scripts
# Author: Byurhan Nurula
# Version: 3.0
# =============================================================================

set -e  # Exit on any error

# Load helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

# Display usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS] [COMPONENTS]

OPTIONS:
    -h, --help          Show this help message
    -c, --capture       Capture current configuration before setup
    -f, --full          Run full setup (all components)
    --skip-xcode        Skip Xcode Command Line Tools installation

COMPONENTS:
    terminal            Setup terminal and shell (zsh, Oh My Zsh)
    apps                Install applications from apps-config.txt
    macos               Configure macOS system preferences
    development         Setup Git, SSH, and development environment
    
EXAMPLES:
    $0 --full                    # Complete setup
    $0 --capture terminal apps   # Capture config then setup terminal and apps
    $0 development              # Setup only development environment
    
EOF
}

# Install Xcode Command Line Tools
install_xcode_tools() {
    log_section "Installing Xcode Command Line Tools"
    
    if xcode-select -p &> /dev/null; then
        log_success "Xcode Command Line Tools already installed"
    else
        log_info "Installing Xcode Command Line Tools..."
        xcode-select --install
        log_warning "Please complete the Xcode installation in the popup, then press Enter to continue"
        read -p ""
    fi
}

# Capture current configuration
capture_current_config() {
    log_section "Capturing Current Configuration"
    
    if [ -f "./scripts/backup-configs.sh" ]; then
        chmod +x "./scripts/backup-configs.sh"
        ./scripts/backup-configs.sh
    else
        log_error "Backup script not found"
        return 1
    fi
}

# Setup terminal and shell
setup_terminal() {
    log_section "Setting up Terminal and Shell"
    
    if [ -f "./scripts/setup-terminal.sh" ]; then
        chmod +x "./scripts/setup-terminal.sh"
        ./scripts/setup-terminal.sh
    else
        log_error "Terminal setup script not found"
        return 1
    fi
}

# Install applications
install_applications() {
    log_section "Installing Applications"
    
    if [ -f "./scripts/install-apps.sh" ]; then
        chmod +x "./scripts/install-apps.sh"
        ./scripts/install-apps.sh
    else
        log_error "App installation script not found"
        return 1
    fi
}

# Configure macOS preferences
configure_macos() {
    log_section "Configuring macOS Preferences"
    
    if [ -f "./scripts/setup-macos-prefs.sh" ]; then
        chmod +x "./scripts/setup-macos-prefs.sh"
        ./scripts/setup-macos-prefs.sh
    else
        log_error "macOS preferences script not found"
        return 1
    fi
}

# Setup development environment
setup_development_env() {
    log_section "Setting up Development Environment"
    
    if [ -f "./scripts/setup-development.sh" ]; then
        chmod +x "./scripts/setup-development.sh"
        ./scripts/setup-development.sh
    else
        log_error "Development setup script not found"
        return 1
    fi
}

# Final summary and next steps
show_summary() {
    log_section "Setup Complete!"
    
    echo -e "${GREEN}🎉 Your macOS development environment is ready!${NC}"
    echo ""
    echo "What was configured:"
    echo "✅ Terminal and shell (zsh, Oh My Zsh, Powerlevel10k)"
    echo "✅ Development applications and CLI tools"
    echo "✅ macOS system preferences"
    echo "✅ Git configuration and SSH keys"
    echo "✅ Development directory structure"
    echo ""
    echo "Next steps:"
    echo "1. Restart your terminal or run: source ~/.zshrc"
    echo "2. Configure Powerlevel10k theme: p10k configure"
    echo "3. Add your SSH key to GitHub/GitLab accounts"
    echo "4. Test your setup by cloning a repository"
    echo ""
    echo "Useful commands:"
    echo "- Update everything: update_all"
    echo "- List installed apps: ./list-installed-apps.sh"
    echo "- Capture current config: ./scripts/capture-current-config.sh"
    echo ""
    log_success "Happy coding! 🚀"
}

# Parse command line arguments
parse_args() {
    local capture_config=false
    local skip_xcode=false
    local components=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -c|--capture)
                capture_config=true
                shift
                ;;
            -f|--full)
                components=("terminal" "apps" "macos" "development")
                shift
                ;;
            --skip-xcode)
                skip_xcode=true
                shift
                ;;
            terminal|apps|macos|development)
                components+=("$1")
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # If no components specified, show usage
    if [ ${#components[@]} -eq 0 ] && [ "$capture_config" = false ]; then
        usage
        exit 1
    fi
    
    echo "$capture_config|$skip_xcode|${components[*]}"
}

# Main execution
main() {
    log_section "macOS Development Environment Setup"
    echo "This script will set up your development environment using modular components"
    echo "Press Enter to continue or Ctrl+C to cancel"
    read -p ""
    
    # Parse arguments
    local args=$(parse_args "$@")
    IFS='|' read -r capture_config skip_xcode components <<< "$args"
    
    # System checks
    check_macos
    ask_for_sudo
    check_internet_connection
    
    # Install Xcode Command Line Tools (unless skipped)
    if [ "$skip_xcode" != "true" ]; then
        install_xcode_tools
    fi
    
    # Capture current configuration if requested
    if [ "$capture_config" = "true" ]; then
        capture_current_config
    fi
    
    # Run selected components
    for component in $components; do
        case $component in
            terminal)
                setup_terminal
                ;;
            apps)
                install_applications
                ;;
            macos)
                configure_macos
                ;;
            development)
                setup_development_env
                ;;
            *)
                log_warning "Unknown component: $component"
                ;;
        esac
    done
    
    show_summary
}

# Run main function with all arguments
main "$@"
