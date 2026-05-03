#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Paperless-NGX - Gestion numérique de documents"

PAPERLESS_DIR="/opt/paperless"
PAPERLESS_USER="paperless"

echo "=== Installation de Paperless-ngx ==="
pkg_install python3 python3-dev python3-pip python3-venv sqlite3

# Création utilisateur
if ! id "$PAPERLESS_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -m -d "$PAPERLESS_DIR" -c "Paperless Service" "$PAPERLESS_USER"
fi

mkdir -p $PAPERLESS_DIR
cd $PAPERLESS_DIR

# Environnement virtuel
python3 -m venv venv
source venv/bin/activate

# Installation
pip install paperless-ngx

# Configuration
cp /opt/paperless/config/paperless.conf.example paperless.conf

# Service
cat > /etc/systemd/system/paperless.service <<'EOF'
[Unit]
Description=Paperless-ngx
After=network.target

[Service]
Type=simple
User=paperless
WorkingDirectory=/opt/paperless
Environment="PATH=/opt/paperless/venv/bin"
ExecStart=/opt/paperless/venv/bin/gunicorn config.wsgi
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable paperless
systemctl start paperless

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8000/tcp
fi

echo
echo "✅ Paperless-ngx en cours d'installation"
echo "URL: http://votre-serveur:8000"
