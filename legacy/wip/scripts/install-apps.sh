#!/bin/bash

# =============================================================================
# App Installation Script
# =============================================================================
# Installs applications based on apps-config.txt
# =============================================================================

# Load helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers.sh"

# Install Homebrew
install_homebrew() {
    log_section "Installing Homebrew"
    
    if command -v brew &> /dev/null; then
        log_success "Homebrew already installed"
        brew update
    else
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        
        log_success "Homebrew installed successfully"
    fi
}

# Read apps configuration file
read_apps_config() {
    local config_file="../apps-config.txt"
    if [ ! -f "$config_file" ]; then
        log_warning "Apps config file not found: $config_file"
        log_info "Using default configuration..."
        return 1
    fi
    return 0
}

# Install CLI tools from configuration
install_cli_tools() {
    log_section "Installing CLI Tools from Configuration"
    
    if ! read_apps_config; then
        log_error "Cannot proceed without apps configuration"
        return 1
    fi
    
    # Read CLI tools from config file
    local tools=()
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        
        # Parse cli: lines
        if [[ "$line" =~ ^cli:([^:]+): ]]; then
            tools+=("${BASH_REMATCH[1]}")
        fi
    done < "../apps-config.txt"
    
    log_info "Found ${#tools[@]} CLI tools to install"
    
    for tool in "${tools[@]}"; do
        if brew list "$tool" &> /dev/null; then
            log_success "$tool already installed"
        else
            log_info "Installing $tool..."
            brew install "$tool" || log_warning "Failed to install $tool"
        fi
    done
}

# Install GUI applications from configuration
install_gui_apps() {
    log_section "Installing GUI Applications from Configuration"
    
    if ! read_apps_config; then
        log_error "Cannot proceed without apps configuration"
        return 1
    fi
    
    # Read GUI apps from config file
    local gui_apps=()
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        
        # Parse cask: lines
        if [[ "$line" =~ ^cask:([^:]+): ]]; then
            gui_apps+=("${BASH_REMATCH[1]}")
        fi
    done < "../apps-config.txt"
    
    log_info "Found ${#gui_apps[@]} GUI applications to install"
    
    for app in "${gui_apps[@]}"; do
        if brew list --cask "$app" &> /dev/null; then
            log_success "$app already installed"
        else
            log_info "Installing $app..."
            brew install --cask "$app" || log_warning "Failed to install $app"
        fi
    done
}

# Install Node Version Manager (NVM)
install_nvm() {
    log_section "Installing Node Version Manager (NVM)"
    
    if [ -d "$HOME/.nvm" ]; then
        log_success "NVM already installed"
    else
        log_info "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        
        # Source NVM
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        log_success "NVM installed successfully"
    fi
    
    # Install Node.js versions
    log_info "Installing Node.js versions..."
    nvm install --lts
    nvm install 18
    nvm install 20
    nvm use --lts
    nvm alias default node
}

# Install VS Code extensions from configuration
install_vscode_extensions() {
    log_section "Installing VS Code Extensions"
    
    if ! command -v code &> /dev/null; then
        log_warning "VS Code not found, skipping extension installation"
        return 0
    fi
    
    if ! read_apps_config; then
        log_error "Cannot proceed without apps configuration"
        return 1
    fi
    
    # Read VS Code extensions from config file
    local extensions=()
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        
        # Parse vscode: lines
        if [[ "$line" =~ ^vscode:([^:]+): ]]; then
            extensions+=("${BASH_REMATCH[1]}")
        fi
    done < "../apps-config.txt"
    
    log_info "Found ${#extensions[@]} VS Code extensions to install"
    
    for extension in "${extensions[@]}"; do
        if code --list-extensions | grep -q "$extension"; then
            log_success "$extension already installed"
        else
            log_info "Installing $extension..."
            code --install-extension "$extension"
        fi
    done
    
    # Copy VS Code settings if they exist
    if [ -f "../legacy/vs-code/settings.json" ]; then
        local vscode_dir="$HOME/Library/Application Support/Code/User"
        mkdir -p "$vscode_dir"
        cp "../legacy/vs-code/settings.json" "$vscode_dir/settings.json"
        log_success "VS Code settings copied"
    fi
}

# Main execution
main() {
    log_section "Application Installation"
    
    check_macos
    check_internet_connection
    
    install_homebrew
    install_cli_tools
    install_gui_apps
    install_nvm
    install_vscode_extensions
    
    # Update and cleanup
    log_info "Updating and cleaning up..."
    brew update && brew upgrade && brew cleanup
    
    log_success "Application installation completed!"
    log_info "All applications have been installed successfully"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
