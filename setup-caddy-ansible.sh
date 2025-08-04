#!/bin/bash
set -e
if [ -z "$HOME" ]; then
  echo "ERROR: \$HOME is not set. Please ensure your environment defines the HOME variable."
  exit 1
fi
if ! command -v apt >/dev/null 2>&1; then
  echo "ERROR: 'apt' package manager not found. This script requires a Debian/Ubuntu-based system with 'apt'."
  exit 1
fi
echo "🚀 Updating system..."
sudo apt update && sudo apt full-upgrade -y

echo "🔧 Installing required packages..."
sudo apt install -y \
  build-essential \
  git \
  curl \
  wget \
  unzip \
  make \
  openssh-client \
  openssh-server \
  python3 \
  python3-venv \
  software-properties-common

echo "🐍 Creating Python virtualenv for Ansible..."
python3 -m venv $HOME/ansible-venv
source $HOME/ansible-venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install ansible

echo "✅ Ansible installed in virtualenv."
echo "   To use it, run: source $HOME/ansible-venv/bin/activate"

echo "📦 Installing Go..."
GO_VERSION=1.22.3
wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz

echo "🛣️ Adding Go to PATH for this session..."
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

if ! grep -q "go/bin" $HOME/.bashrc; then
  echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bashrc
fi

echo "🐹 Installing xcaddy..."
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

echo "✅ Setup complete!"
echo "➡️ Run this when you log in:"
echo "   source $HOME/ansible-venv/bin/activate"
echo ""
echo "➡️ You can now run:"
echo "   xcaddy build ..."
echo "   ansible-playbook -i inventory site.yml"
