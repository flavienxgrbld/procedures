#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Request Bin - Débogage de webhooks HTTP"

REQUESTBIN_DIR="/opt/requestbin"

echo "=== Installation de RequestBin ==="
pkg_install python3 python3-pip python3-dev redis-server

# Création répertoire
mkdir -p $REQUESTBIN_DIR
cd $REQUESTBIN_DIR

# Installation
git clone https://github.com/Runscope/requestbin.git . || true

# Dépendances
pip3 install -r requirements.txt

# Service Redis
systemctl enable redis-server
systemctl start redis-server

# Service
cat > /etc/systemd/system/requestbin.service <<'EOF'
[Unit]
Description=RequestBin
After=network.target redis-server.target

[Service]
Type=simple
WorkingDirectory=/opt/requestbin
ExecStart=gunicorn app:app -b 0.0.0.0:5000
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable requestbin
systemctl start requestbin

if command -v ufw >/dev/null 2>&1; then
    ufw allow 5000/tcp
fi

echo
echo "✅ RequestBin en cours d'installation"
echo "URL: http://votre-serveur:5000"
