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

info "Apache - Serveur web modulaire"

echo "=== Installation d'Apache ==="

case "$PKG_MANAGER" in
    apt)
        pkg_install apache2 apache2-utils
        ;;
    dnf|yum)
        pkg_install httpd httpd-utils
        ;;
    zypper)
        pkg_install apache2 apache2-utils
        ;;
    pacman)
        pkg_install apache
        ;;
esac

# Service
systemctl enable apache2 2>/dev/null || systemctl enable httpd
systemctl start apache2 2>/dev/null || systemctl start httpd

if command -v ufw >/dev/null 2>&1; then
    ufw allow 80/tcp
    ufw allow 443/tcp
fi

echo
echo "✅ Apache installé avec succès"
echo "Fichiers de configuration: /etc/apache2/apache2.conf"
echo "Répertoire de sites: /etc/apache2/sites-available"
