#!/usr/bin/env bash

set -euo pipefail

COMMON_SCRIPT="/tmp/install_common.sh"
if [ ! -f "$COMMON_SCRIPT" ]; then
    curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/install-scripts/main/root/common/install_common.sh" -o "$COMMON_SCRIPT"
fi
source "$COMMON_SCRIPT"

ensure_root
detect_os
detect_package_manager

info "Strapi - CMS Headless API-First"

STRAPI_DIR="/opt/strapi"
STRAPI_USER="strapi"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

# Installation Node.js
echo "=== Installation de Node.js ==="
case "$PKG_MANAGER" in
    apt)
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        pkg_install nodejs
        ;;
    dnf|yum)
        pkg_install nodejs npm
        ;;
    zypper)
        pkg_install nodejs npm
        ;;
    pacman)
        pkg_install nodejs npm
        ;;
esac

# Installation PostgreSQL et Redis
pkg_install postgresql redis-server

# Création utilisateur
if ! id "$STRAPI_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -m -d "$STRAPI_DIR" -c "Strapi Service" "$STRAPI_USER"
fi

# Installation Strapi
echo "=== Installation de Strapi ==="
mkdir -p "$STRAPI_DIR"
cd "$STRAPI_DIR"

sudo -u "$STRAPI_USER" npx create-strapi-app@latest . --quickstart

# Service systemd
cat > /etc/systemd/system/strapi.service <<EOF
[Unit]
Description=Strapi CMS
After=network.target

[Service]
Type=simple
User=$STRAPI_USER
WorkingDirectory=$STRAPI_DIR
ExecStart=/usr/bin/npm start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable strapi
systemctl start strapi

if command -v ufw >/dev/null 2>&1; then
    ufw allow 1337/tcp
fi

echo
echo "✅ Strapi en cours d'installation"
echo "URL: http://votre-serveur:1337"
