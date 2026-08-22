#!/bin/bash

# =============================================================================
# Development Environment Setup
# =============================================================================
# Sets up Git, SSH keys, and development configurations
# =============================================================================

# Load helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers.sh"

# Setup SSH keys for Git
setup_ssh_keys() {
    log_section "Setting up SSH Keys for Git"
    
    local ssh_dir="$HOME/.ssh"
    local ssh_key="$ssh_dir/id_ed25519"
    
    # Create .ssh directory if it doesn't exist
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    
    if [ -f "$ssh_key" ]; then
        log_success "SSH key already exists at $ssh_key"
    else
        log_info "Generating new SSH key..."
        read -p "Enter your email for SSH key: " ssh_email
        
        ssh-keygen -t ed25519 -C "$ssh_email" -f "$ssh_key" -N ""
        
        # Start ssh-agent and add key
        eval "$(ssh-agent -s)"
        ssh-add "$ssh_key"
        
        # Create SSH config
        cat > "$ssh_dir/config" << EOF
Host github.com
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519

Host gitlab.com
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519
EOF
        
        chmod 600 "$ssh_dir/config"
        
        log_success "SSH key generated successfully!"
        log_info "Your public key:"
        cat "$ssh_key.pub"
        log_warning "Please add this key to your GitHub/GitLab account"
        log_info "GitHub: https://github.com/settings/keys"
        log_info "GitLab: https://gitlab.com/-/profile/keys"
        
        read -p "Press Enter after adding the key to continue..."
    fi
}

# Setup Git configuration
setup_git_config() {
    log_section "Setting up Git Configuration"
    
    # Copy git config if it exists in config folder
    if [ -f "../config/.gitconfig" ]; then
        log_info "Installing Git configuration from config folder..."
        cp "../config/.gitconfig" "$HOME/.gitconfig"
        log_success "Git configuration installed"
    elif [ -f "../current/.gitconfig" ]; then
        log_info "Using existing Git configuration..."
        cp "../current/.gitconfig" "$HOME/.gitconfig"
        log_success "Git configuration copied"
    else
        log_info "Setting up new Git configuration..."
        read -p "Enter your Git username: " git_username
        read -p "Enter your Git email: " git_email
        
        git config --global user.name "$git_username"
        git config --global user.email "$git_email"
        git config --global init.defaultBranch main
        git config --global pull.rebase false
        git config --global core.editor "code --wait"
        
        log_success "Git configuration completed"
    fi
    
    # Setup global gitignore
    if [ -f "../config/.gitignore-global" ]; then
        cp "../config/.gitignore-global" "$HOME/.gitignore-global"
        git config --global core.excludesfile "$HOME/.gitignore-global"
        log_success "Global gitignore configured from config folder"
    elif [ -f "../current/.gitignore-global" ]; then
        cp "../current/.gitignore-global" "$HOME/.gitignore-global"
        git config --global core.excludesfile "$HOME/.gitignore-global"
        log_success "Global gitignore configured from current folder"
    fi
}

# Create development directory structure
create_dev_structure() {
    log_section "Creating Development Directory Structure"
    
    local directories=(
        "$HOME/dev"
        "$HOME/dev/personal"
        "$HOME/dev/work"
        "$HOME/dev/learning"
        "$HOME/dev/tools"
        "$HOME/dev/scripts"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_success "Created directory: $dir"
        else
            log_success "Directory already exists: $dir"
        fi
    done
}

# Setup database configurations (based on your current setup)
setup_database_configs() {
    log_section "Setting up Database Configurations"
    
    # Create database aliases for your workflow
    log_info "Adding database service aliases to shell..."
    
    # These will be added to .zshrc by the terminal setup script
    # Just ensure services are configured to start on boot if needed
    
    if command -v brew &> /dev/null; then
        # MySQL
        if brew list mysql &> /dev/null; then
            log_info "MySQL installed via Homebrew"
            log_info "Use: brew services start mysql"
        fi
        
        # Redis
        if brew list redis &> /dev/null; then
            log_info "Redis installed via Homebrew"
            log_info "Use: brew services start redis"
        fi
        
        # PostgreSQL
        if brew list postgresql &> /dev/null; then
            log_info "PostgreSQL installed via Homebrew"
            log_info "Use: brew services start postgresql"
        fi
    fi
    
    # Milvus setup (from your current configuration)
    if [ -f "../current-latest/milvus/docker-compose.yml" ]; then
        log_info "Setting up Milvus database..."
        mkdir -p "$HOME/milvus-db"
        cp "../current-latest/milvus/"* "$HOME/milvus-db/" 2>/dev/null || true
        log_success "Milvus configuration restored"
        log_info "Use: milvus.start and milvus.stop aliases"
    fi
}

# Main execution
main() {
    log_section "Development Environment Setup"
    
    check_macos
    check_internet_connection
    
    setup_ssh_keys
    setup_git_config
    create_dev_structure
    setup_database_configs
    
    log_success "Development environment setup completed!"
    log_info "Next steps:"
    log_info "1. Add your SSH key to GitHub/GitLab"
    log_info "2. Test Git access: git clone git@github.com:username/repo.git"
    log_info "3. Start database services as needed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
