#!/usr/bin/env bash

set -euo pipefail

# Bibliothèque commune : copie du dépôt en priorité, téléchargement sinon.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/../install_common.sh"
if [ ! -f "$COMMON_SCRIPT" ]; then
    COMMON_SCRIPT="$(mktemp)"
    curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/procedures/main/install_common.sh" -o "$COMMON_SCRIPT"
fi
# shellcheck source=../install_common.sh
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
