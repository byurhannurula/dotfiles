#!/bin/bash

# =============================================================================
# Terminal Setup Script
# =============================================================================
# Sets up zsh, Oh My Zsh, and terminal configuration
# =============================================================================

# Load helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers.sh"

# Install Oh My Zsh and plugins
install_oh_my_zsh() {
    log_section "Installing Oh My Zsh and Plugins"
    
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_success "Oh My Zsh already installed"
    else
        log_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log_success "Oh My Zsh installed successfully"
    fi
    
    # Install plugins
    local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    
    # zsh-autosuggestions
    if [ ! -d "$plugins_dir/zsh-autosuggestions" ]; then
        log_info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"
    fi
    
    # zsh-syntax-highlighting
    if [ ! -d "$plugins_dir/zsh-syntax-highlighting" ]; then
        log_info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins_dir/zsh-syntax-highlighting"
    fi
    
    # zsh-completions
    if [ ! -d "$plugins_dir/zsh-completions" ]; then
        log_info "Installing zsh-completions..."
        git clone https://github.com/zsh-users/zsh-completions "$plugins_dir/zsh-completions"
    fi
    
    # powerlevel10k theme
    local themes_dir="$HOME/.oh-my-zsh/custom/themes"
    if [ ! -d "$themes_dir/powerlevel10k" ]; then
        log_info "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$themes_dir/powerlevel10k"
    fi
}

# Setup shell configuration
setup_shell_config() {
    log_section "Setting up Shell Configuration"
    
    # Backup existing configs
    backup_file "$HOME/.zshrc"
    backup_file "$HOME/.zshenv"
    
    # Copy new configurations
    if [ -f "../config/.zshrc" ]; then
        log_info "Installing modern .zshrc configuration..."
        cp "../config/.zshrc" "$HOME/.zshrc"
        log_success "Shell configuration installed"
    else
        log_error "Configuration file not found: ../config/.zshrc"
        return 1
    fi
    
    # Handle .zshenv (preserve existing environment setups)
    if [ -f "../current/.zshenv" ]; then
        log_info "Preserving existing .zshenv..."
        cp "../current/.zshenv" "$HOME/.zshenv"
    elif [ -f "$HOME/.zshenv" ]; then
        log_info "Keeping existing .zshenv"
    else
        log_info "Creating minimal .zshenv..."
        cat > "$HOME/.zshenv" << 'EOF'
# Rust/Cargo
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Add any additional environment variables here
EOF
    fi
}

# Main execution
main() {
    log_section "Terminal and Shell Setup"
    
    check_macos
    check_internet_connection
    
    install_oh_my_zsh
    setup_shell_config
    
    log_success "Terminal setup completed!"
    log_info "Next steps:"
    log_info "1. Restart your terminal or run: source ~/.zshrc"
    log_info "2. Configure Powerlevel10k: p10k configure"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
