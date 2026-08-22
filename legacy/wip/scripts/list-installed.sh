#!/bin/bash

# =============================================================================
# List All Installed Applications and Tools
# =============================================================================
# Simple, focused script to display what's currently installed
# =============================================================================

# Load helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers.sh"

log_section "Currently Installed Apps and Tools"

# Homebrew packages
echo ""
echo "📦 Homebrew Packages:"
echo "--------------------"
if command -v brew &> /dev/null; then
    echo "Formulae (CLI tools):"
    brew list --formula
    echo ""
    echo "Casks (GUI applications):"
    brew list --cask
    echo ""
    echo "Taps (repositories):"
    brew tap
else
    echo "❌ Homebrew not installed"
fi

# Node.js versions
echo ""
echo "🟢 Node.js:"
echo "-----------"
if command -v nvm &> /dev/null; then
    echo "NVM versions:"
    nvm list
else
    echo "❌ NVM not installed"
    if command -v node &> /dev/null; then
        echo "✅ Node.js: $(node --version)"
    fi
fi

# Global npm packages
echo ""
echo "📦 Global NPM Packages:"
echo "----------------------"
if command -v npm &> /dev/null; then
    npm list -g --depth=0 2>/dev/null | grep -v "^├──\|^└──" | tail -n +2 || echo "No global packages"
else
    echo "❌ NPM not available"
fi

# Programming languages
echo ""
echo "💻 Programming Languages:"
echo "------------------------"
if command -v python3 &> /dev/null; then
    echo "✅ Python3: $(python3 --version)"
fi
if command -v ruby &> /dev/null; then
    echo "✅ Ruby: $(ruby --version | cut -d' ' -f1-2)"
fi
if command -v cargo &> /dev/null; then
    echo "✅ Rust: $(rustc --version | cut -d' ' -f1-2)"
fi
if command -v go &> /dev/null; then
    echo "✅ Go: $(go version | cut -d' ' -f1-3)"
fi
if command -v java &> /dev/null; then
    echo "✅ Java: $(java --version 2>&1 | head -1 | cut -d' ' -f1-2)"
fi

# Database tools
echo ""
echo "🗄️  Databases:"
echo "-------------"
if command -v mysql &> /dev/null; then
    echo "✅ MySQL: $(mysql --version | cut -d' ' -f1-3)"
fi
if command -v redis-server &> /dev/null; then
    echo "✅ Redis: $(redis-server --version | cut -d' ' -f1-3)"
fi
if command -v postgres &> /dev/null; then
    echo "✅ PostgreSQL: $(postgres --version | cut -d' ' -f1-3)"
fi

# Package managers
echo ""
echo "📦 Package Managers:"
echo "-------------------"
if command -v npm &> /dev/null; then
    echo "✅ NPM: $(npm --version)"
fi
if command -v yarn &> /dev/null; then
    echo "✅ Yarn: $(yarn --version)"
fi
if command -v pnpm &> /dev/null; then
    echo "✅ PNPM: $(pnpm --version)"
fi

# macOS Applications
echo ""
echo "🖥️  macOS Applications:"
echo "----------------------"
echo "Applications in /Applications:"
ls /Applications/ | grep -E "\\.app$" | head -20
if [ $(ls /Applications/ | grep -E "\\.app$" | wc -l) -gt 20 ]; then
    echo "... and $(($(ls /Applications/ | grep -E "\\.app$" | wc -l) - 20)) more"
fi

# VS Code extensions
echo ""
echo "🔧 VS Code Extensions:"
echo "---------------------"
if command -v code &> /dev/null; then
    code --list-extensions | head -10
    if [ $(code --list-extensions | wc -l) -gt 10 ]; then
        echo "... and $(($(code --list-extensions | wc -l) - 10)) more"
    fi
else
    echo "❌ VS Code CLI not available"
fi

echo ""
echo "✅ Scan complete!"
