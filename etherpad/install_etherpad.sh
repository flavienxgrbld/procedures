#!/usr/bin/env bash

set -euo pipefail

# Bibliothèque commune : copie du dépôt en priorité, téléchargement sinon.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/../install_common.sh"
if [ ! -f "$COMMON_SCRIPT" ]; then
    COMMON_SCRIPT="$(mktemp)"
    curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/install-scripts/main/root/common/install_common.sh" -o "$COMMON_SCRIPT"
fi
# shellcheck source=../install_common.sh
source "$COMMON_SCRIPT"

ensure_root
detect_os
detect_package_manager

info "Crowdfunding - EtherPad alternative collaborative writing"

ETHERPAD_DIR="/opt/etherpad"
ETHERPAD_USER="etherpad"

echo "=== Installation d'Etherpad Lite ==="
pkg_install nodejs npm git python3

# Création utilisateur
if ! id "$ETHERPAD_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -m -d "$ETHERPAD_DIR" -c "Etherpad Service" "$ETHERPAD_USER"
fi

mkdir -p $ETHERPAD_DIR
cd $ETHERPAD_DIR

# Clone repository
git clone https://github.com/ether/etherpad-lite.git . || true

# Installation
npm install

# Service
cat > /etc/systemd/system/etherpad.service <<'EOF'
[Unit]
Description=Etherpad Lite
After=network.target

[Service]
Type=simple
User=etherpad
WorkingDirectory=/opt/etherpad
ExecStart=/opt/etherpad/bin/run.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable etherpad
systemctl start etherpad

if command -v ufw >/dev/null 2>&1; then
    ufw allow 9001/tcp
fi

echo
echo "✅ Etherpad Lite en cours d'installation"
echo "URL: http://votre-serveur:9001"
