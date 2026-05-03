#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

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
