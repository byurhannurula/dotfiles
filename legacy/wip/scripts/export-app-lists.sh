#!/bin/bash

# =============================================================================
# Export Application Lists for Configuration
# =============================================================================
# Exports current installations to files that can be reviewed and used
# to update apps-config.txt
# =============================================================================

# Load helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers.sh"

# Create exports directory
EXPORT_DIR="./exports-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$EXPORT_DIR"

log_section "Exporting Application Lists"

# Homebrew packages
log_info "Exporting Homebrew packages..."
if command -v brew &> /dev/null; then
    echo "# Homebrew Formulae (CLI tools)" > "$EXPORT_DIR/brew-formulae.txt"
    brew list --formula | while read formula; do
        desc=$(brew info "$formula" 2>/dev/null | head -1 | cut -d':' -f2- | sed 's/^ *//' || echo "")
        echo "cli:$formula:$desc" >> "$EXPORT_DIR/brew-formulae.txt"
    done
    
    echo "# Homebrew Casks (GUI applications)" > "$EXPORT_DIR/brew-casks.txt"
    brew list --cask | while read cask; do
        desc=$(brew info --cask "$cask" 2>/dev/null | head -1 | cut -d':' -f2- | sed 's/^ *//' || echo "")
        echo "cask:$cask:$desc" >> "$EXPORT_DIR/brew-casks.txt"
    done
    
    brew tap > "$EXPORT_DIR/brew-taps.txt"
    log_success "Homebrew packages exported"
else
    echo "Homebrew not installed" > "$EXPORT_DIR/brew-formulae.txt"
fi

# Node.js versions
log_info "Exporting Node.js versions..."
if command -v nvm &> /dev/null; then
    nvm list > "$EXPORT_DIR/nvm-versions.txt" 2>&1
else
    echo "NVM not installed" > "$EXPORT_DIR/nvm-versions.txt"
    if command -v node &> /dev/null; then
        echo "Node.js: $(node --version)" >> "$EXPORT_DIR/nvm-versions.txt"
    fi
fi

# Global npm packages
log_info "Exporting global npm packages..."
if command -v npm &> /dev/null; then
    echo "# Global NPM packages" > "$EXPORT_DIR/npm-global.txt"
    npm list -g --depth=0 --parseable 2>/dev/null | grep -v "^$HOME" | while read pkg; do
        pkg_name=$(basename "$pkg")
        if [ "$pkg_name" != "npm" ]; then
            echo "npm:$pkg_name:Global npm package" >> "$EXPORT_DIR/npm-global.txt"
        fi
    done
else
    echo "NPM not available" > "$EXPORT_DIR/npm-global.txt"
fi

# VS Code extensions
log_info "Exporting VS Code extensions..."
if command -v code &> /dev/null; then
    echo "# VS Code Extensions" > "$EXPORT_DIR/vscode-extensions.txt"
    code --list-extensions | while read ext; do
        echo "vscode:$ext:VS Code extension" >> "$EXPORT_DIR/vscode-extensions.txt"
    done
else
    echo "VS Code not available" > "$EXPORT_DIR/vscode-extensions.txt"
fi

# macOS Applications
log_info "Exporting macOS applications..."
echo "# macOS Applications" > "$EXPORT_DIR/macos-apps.txt"
ls /Applications/ | grep -E "\\.app$" | while read app; do
    app_name=$(echo "$app" | sed 's/\.app$//')
    echo "# $app_name" >> "$EXPORT_DIR/macos-apps.txt"
done

# Create summary with instructions
cat > "$EXPORT_DIR/README.md" << EOF
# Application Export - $(date)

This directory contains lists of currently installed applications that can be used to update your \`apps-config.txt\`.

## Files

- \`brew-formulae.txt\` - Homebrew CLI tools (ready for apps-config.txt)
- \`brew-casks.txt\` - Homebrew GUI apps (ready for apps-config.txt)  
- \`vscode-extensions.txt\` - VS Code extensions (ready for apps-config.txt)
- \`npm-global.txt\` - Global npm packages (ready for apps-config.txt)
- \`nvm-versions.txt\` - Node.js versions installed
- \`macos-apps.txt\` - macOS applications (for reference)
- \`brew-taps.txt\` - Homebrew repositories

## Usage

1. **Review the exported files** - Check what's installed
2. **Copy relevant lines** to \`../apps-config.txt\`
3. **Comment out** apps you don't want: \`# cli:unwanted-app:description\`
4. **Test the configuration** with \`./setup.sh apps\`

## Example

From \`brew-formulae.txt\`:
\`\`\`
cli:git:Version control system
cli:node:JavaScript runtime
\`\`\`

Copy to \`apps-config.txt\` and uncomment what you want:
\`\`\`
cli:git:Version control system
cli:node:JavaScript runtime
# cli:unwanted-tool:Some tool I don't need
\`\`\`
EOF

# Create symlink to latest
rm -f "./exports-latest" 2>/dev/null
ln -s "$(basename "$EXPORT_DIR")" "./exports-latest"

log_success "Application lists exported to: $EXPORT_DIR"
log_info "Review files and copy relevant entries to apps-config.txt"
log_info "Latest export: ./exports-latest"
