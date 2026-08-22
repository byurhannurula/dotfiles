#!/bin/bash

# =============================================================================
# Backup Essential Configurations Only
# =============================================================================
# This script backs up ONLY essential configuration files (no SSH keys)
# Safe for public repositories - only configs that can be shared
# =============================================================================

# Load helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers.sh"

# Create backup directory with timestamp
BACKUP_DIR="./current-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

log_section "Backing Up Essential Configurations"

# Essential shell configurations
log_info "Backing up shell configurations..."
[ -f "$HOME/.zshrc" ] && cp "$HOME/.zshrc" "$BACKUP_DIR/.zshrc"
[ -f "$HOME/.zshenv" ] && cp "$HOME/.zshenv" "$BACKUP_DIR/.zshenv"
[ -f "$HOME/.zprofile" ] && cp "$HOME/.zprofile" "$BACKUP_DIR/.zprofile"
[ -f "$HOME/.profile" ] && cp "$HOME/.profile" "$BACKUP_DIR/.profile"

# Git configuration
log_info "Backing up Git configuration..."
[ -f "$HOME/.gitconfig" ] && cp "$HOME/.gitconfig" "$BACKUP_DIR/.gitconfig"
[ -f "$HOME/.gitignore-global" ] && cp "$HOME/.gitignore-global" "$BACKUP_DIR/.gitignore-global"

# SSH config only (NO KEYS EVER)
log_info "Backing up SSH config (NO KEYS)..."
if [ -d "$HOME/.ssh" ]; then
    mkdir -p "$BACKUP_DIR/.ssh"
    [ -f "$HOME/.ssh/config" ] && cp "$HOME/.ssh/config" "$BACKUP_DIR/.ssh/config"
    echo "SSH keys are NOT backed up for security" > "$BACKUP_DIR/.ssh/README.txt"
fi

# VS Code settings
log_info "Backing up VS Code settings..."
VSCODE_DIR="$HOME/Library/Application Support/Code/User"
if [ -d "$VSCODE_DIR" ]; then
    mkdir -p "$BACKUP_DIR/vscode"
    [ -f "$VSCODE_DIR/settings.json" ] && cp "$VSCODE_DIR/settings.json" "$BACKUP_DIR/vscode/settings.json"
    [ -f "$VSCODE_DIR/keybindings.json" ] && cp "$VSCODE_DIR/keybindings.json" "$BACKUP_DIR/vscode/keybindings.json"
fi

# iTerm2 configuration
log_info "Backing up iTerm2 configuration..."
ITERM_PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
[ -f "$ITERM_PLIST" ] && cp "$ITERM_PLIST" "$BACKUP_DIR/com.googlecode.iterm2.plist"

# Create summary
cat > "$BACKUP_DIR/README.md" << EOF
# Configuration Backup - $(date)

## Safe Configurations (No Sensitive Data)

### Shell Configuration
- \`.zshrc\` - Main zsh configuration
- \`.zshenv\` - Environment variables
- \`.zprofile\` - Profile configuration
- \`.profile\` - General profile

### Development
- \`.gitconfig\` - Git configuration
- \`.gitignore-global\` - Global gitignore

### Applications
- \`vscode/\` - VS Code settings
- \`com.googlecode.iterm2.plist\` - iTerm2 configuration

### Security
- \`.ssh/config\` - SSH configuration only
- **NO SSH KEYS** - Never backed up for security

## Usage
Copy files to their original locations and restart applications as needed.
EOF

# Create symlink to latest
rm -f "./current-latest" 2>/dev/null
ln -s "$(basename "$BACKUP_DIR")" "./current-latest"

log_success "Configuration backup completed: $BACKUP_DIR"
log_info "Only safe configurations backed up (no sensitive data)"
log_info "Latest backup: ./current-latest"
