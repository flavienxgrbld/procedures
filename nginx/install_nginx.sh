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

info "Nginx - Serveur web haute performance"

echo "=== Installation de Nginx ==="

case "$PKG_MANAGER" in
    apt)
        pkg_install nginx
        ;;
    dnf|yum)
        pkg_install nginx
        ;;
    zypper)
        pkg_install nginx
        ;;
    pacman)
        pkg_install nginx
        ;;
esac

# Service
systemctl enable nginx
systemctl start nginx

if command -v ufw >/dev/null 2>&1; then
    ufw allow 80/tcp
    ufw allow 443/tcp
fi

echo
echo "✅ Nginx installé avec succès"
echo "Fichiers de configuration: /etc/nginx/nginx.conf"
echo "Répertoire de sites: /etc/nginx/sites-available"
