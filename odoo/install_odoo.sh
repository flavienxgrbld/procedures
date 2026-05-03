#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Odoo - ERP/CRM open source complet"

ODOO_VERSION="16.0"
ODOO_USER="odoo"
ODOO_HOME="/opt/odoo"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

# Installation dépendances
echo "=== Installation des dépendances ==="
pkg_install git python3 python3-dev python3-pip libxml2-dev libxslt1-dev libjpeg-dev zlib1g-dev

# Installation PostgreSQL
install_database

# Création utilisateur Odoo
if ! id "$ODOO_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -m -d "$ODOO_HOME" -c "Odoo Service" "$ODOO_USER"
fi

# Installation Odoo
echo "=== Installation d'Odoo ==="
cd "$ODOO_HOME"
sudo -u "$ODOO_USER" git clone --depth 1 --branch $ODOO_VERSION https://github.com/odoo/odoo.git .

cd "$ODOO_HOME"
sudo -u "$ODOO_USER" pip install -r requirements.txt

# Service systemd
cat > /etc/systemd/system/odoo.service <<EOF
[Unit]
Description=Odoo
After=network.target postgresql.service

[Service]
Type=simple
User=$ODOO_USER
ExecStart=/usr/bin/python3 $ODOO_HOME/odoo-bin -c $ODOO_HOME/odoo.conf
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable odoo
systemctl start odoo

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8069/tcp
    ufw allow 8072/tcp
fi

echo
echo "✅ Odoo en cours d'installation"
echo "URL: http://votre-serveur:8069"
echo "Port XML-RPC: 8072"
