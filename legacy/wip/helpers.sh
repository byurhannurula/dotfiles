#!/usr/bin/env bash

# =============================================================================
# Helper Functions for macOS Setup
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_section() {
    echo -e "\n${PURPLE}🚀 $1${NC}"
    echo "=============================================="
}

# Legacy function names for compatibility
print_success() {
    log_success "$1"
}

print_error() {
    log_error "$1"
}

print_success_muted() {
    log_info "$1"
}

step() {
    log_info "$1"
}

# System checks
check_bash_version() {
    if ((BASH_VERSINFO[0] < 3)); then
        log_error "Sorry, you need at least bash-3.0 to run this script."
        exit 1
    fi
}

check_internet_connection() {
    if ! ping -q -w1 -c1 google.com &>/dev/null; then
        log_error "Please check your internet connection"
        exit 1
    else
        log_success "Internet connection verified"
    fi
}

check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only"
        exit 1
    fi
}

# Sudo management
ask_for_sudo() {
    log_info "This script requires sudo access for some installations"
    sudo -v &>/dev/null

    # Keep-alive: update existing `sudo` time stamp until script has finished
    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &

    log_success "Password cached"
}

# File operations
download_file() {
    local url="$1"
    local destination="$2"
    local description="${3:-file}"
    
    log_info "Downloading $description..."
    if curl -fsSL "$url" -o "$destination"; then
        log_success "$description downloaded successfully"
        return 0
    else
        log_error "Failed to download $description from $url"
        return 1
    fi
}

backup_file() {
    local file="$1"
    local backup_suffix="${2:-.backup.$(date +%Y%m%d_%H%M%S)}"
    
    if [ -f "$file" ]; then
        cp "$file" "${file}${backup_suffix}"
        log_info "Backed up $file to ${file}${backup_suffix}"
    fi
}

# App installation helpers
install_if_missing() {
    local app="$1"
    local install_command="$2"
    local check_command="${3:-command -v $app}"
    
    if eval "$check_command" &> /dev/null; then
        log_success "$app already installed"
        return 0
    else
        log_info "Installing $app..."
        if eval "$install_command"; then
            log_success "$app installed successfully"
            return 0
        else
            log_error "Failed to install $app"
            return 1
        fi
    fi
}

# Configuration helpers
set_macos_preference() {
    local domain="$1"
    local key="$2"
    local type="$3"
    local value="$4"
    local description="$5"
    
    log_info "Setting: $description"
    defaults write "$domain" "$key" -"$type" "$value"
}

# Network helpers
test_connection() {
    local host="${1:-google.com}"
    local timeout="${2:-5}"
    
    if timeout "$timeout" ping -c 1 "$host" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Git helpers
setup_git_config() {
    local key="$1"
    local value="$2"
    local global="${3:-true}"
    
    if [ "$global" = "true" ]; then
        git config --global "$key" "$value"
    else
        git config "$key" "$value"
    fi
    log_info "Set git config: $key = $value"
}

# SSH helpers
generate_ssh_key() {
    local email="$1"
    local key_type="${2:-ed25519}"
    local key_file="$HOME/.ssh/id_$key_type"
    
    if [ -f "$key_file" ]; then
        log_success "SSH key already exists: $key_file"
        return 0
    fi
    
    log_info "Generating SSH key..."
    ssh-keygen -t "$key_type" -C "$email" -f "$key_file" -N ""
    
    # Add to ssh-agent
    eval "$(ssh-agent -s)"
    ssh-add "$key_file"
    
    log_success "SSH key generated: $key_file"
    return 0
}

# Cleanup helpers
cleanup_downloads() {
    local download_dir="${1:-/tmp}"
    log_info "Cleaning up temporary files in $download_dir"
    find "$download_dir" -name "*.tmp" -delete 2>/dev/null || true
}

restart_services() {
    local services=("$@")
    for service in "${services[@]}"; do
        log_info "Restarting $service..."
        killall "$service" &> /dev/null || true
    done
}