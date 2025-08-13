#!/bin/bash
set -e

# Configuration - can be overridden via environment variables
GO_VERSION=${GO_VERSION:-"1.22.3"}
ANSIBLE_VERSION=${ANSIBLE_VERSION:-"latest"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Cleanup function
cleanup() {
    if [ -f "/tmp/go.tar.gz" ]; then
        rm -f /tmp/go.tar.gz
        print_status "Cleaned up temporary files"
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
    exit 1
fi

# Check if HOME is set
if [ -z "$HOME" ]; then
    print_error "\$HOME is not set. Please ensure your environment defines the HOME variable."
    exit 1
fi

# Check if user has sudo privileges
if ! sudo -n true 2>/dev/null; then
    print_error "This script requires sudo privileges. Please ensure you can run sudo commands."
    exit 1
fi

# Check if apt is available
if ! command -v apt >/dev/null 2>&1; then
    print_error "'apt' package manager not found. This script requires a Debian/Ubuntu-based system with 'apt'."
    exit 1
fi

# Note: python3 will be installed by apt, so no need to check for it here

print_status "🚀 Updating system..."
if ! sudo apt update && sudo apt full-upgrade -y; then
    print_error "System update failed"
    exit 1
fi

print_status "🔧 Installing required packages..."
if ! sudo apt install -y \
    build-essential \
    git \
    curl \
    wget \
    unzip \
    make \
    yq \
    openssh-client \
    openssh-server \
    python3 \
    python3-venv \
    software-properties-common; then
    print_error "Package installation failed"
    exit 1
fi

print_status "🐍 Creating Python virtualenv for Ansible..."
if [ -d "$HOME/ansible-venv" ]; then
    print_warning "Ansible virtualenv already exists. Removing and recreating..."
    rm -rf "$HOME/ansible-venv"
fi

if ! python3 -m venv "$HOME/ansible-venv"; then
    print_error "Failed to create Python virtualenv"
    exit 1
fi

# Source the virtualenv
if ! source "$HOME/ansible-venv/bin/activate"; then
    print_error "Failed to activate virtualenv"
    exit 1
fi

print_status "Installing Ansible..."
if ! pip install --upgrade pip setuptools wheel; then
    print_error "Failed to upgrade pip"
    exit 1
fi

if ! pip install "ansible${ANSIBLE_VERSION:+==$ANSIBLE_VERSION}"; then
    print_error "Failed to install Ansible"
    exit 1
fi

print_success "Ansible installed in virtualenv."
print_status "   To use it, run: source $HOME/ansible-venv/bin/activate"

print_status "📦 Installing Go ${GO_VERSION}..."
GO_ARCHIVE="go${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/${GO_ARCHIVE}"

# Download Go with error checking
if ! wget -q "$GO_URL" -O "/tmp/go.tar.gz"; then
    print_error "Failed to download Go"
    exit 1
fi

# Verify the download (basic size check)
if [ ! -s "/tmp/go.tar.gz" ]; then
    print_error "Downloaded Go archive is empty or corrupted"
    exit 1
fi

# Remove existing Go installation
if [ -d "/usr/local/go" ]; then
    sudo rm -rf /usr/local/go
fi

# Extract Go
if ! sudo tar -C /usr/local -xzf /tmp/go.tar.gz; then
    print_error "Failed to extract Go"
    exit 1
fi

# Verify Go installation
if ! /usr/local/go/bin/go version >/dev/null 2>&1; then
    print_error "Go installation verification failed"
    exit 1
fi

print_success "Go ${GO_VERSION} installed successfully"

print_status "🛣️ Adding Go to PATH..."
# Add to current session
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Add to .bashrc if not already present
if ! grep -q "/usr/local/go/bin" "$HOME/.bashrc"; then
    if echo '' >> "$HOME/.bashrc" 2>/dev/null && \
       echo '# Go installation' >> "$HOME/.bashrc" 2>/dev/null && \
       echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$HOME/.bashrc" 2>/dev/null; then
        print_success "Added Go to PATH in .bashrc"
    else
        print_warning "Could not write to .bashrc - Go will only be available in current session"
        print_warning "You may need to manually add to your shell profile:"
        print_warning "  export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin"
    fi
else
    print_warning "Go PATH already exists in .bashrc"
fi

print_status "🐹 Installing xcaddy..."
# Ensure Go is in PATH for this session
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

if ! go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest; then
    print_error "Failed to install xcaddy"
    exit 1
fi

# Verify xcaddy installation
if ! command -v xcaddy >/dev/null 2>&1; then
    print_error "xcaddy installation verification failed"
    exit 1
fi

print_success "Setup complete!"
echo ""
print_status "➡️ Run this when you log in:"
echo "   source ~/ansible-venv/bin/activate"
echo ""
print_status "➡️ You can now run:"
echo "   xcaddy build ..."
echo "   ansible-playbook -i inventory site.yml"
echo ""
print_status "➡️ Go version: $(/usr/local/go/bin/go version)"
print_status "➡️ Ansible version: $(source $HOME/ansible-venv/bin/activate && ansible --version | head -n1)"
print_status "➡️ xcaddy version: $(xcaddy version)"
