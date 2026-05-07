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

info "Jellyfin - Serveur multimédia open source"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

echo "=== Installation de Jellyfin ==="
case "$PKG_MANAGER" in
    apt)
        curl -s https://repo.jellyfin.org/install-debuntu.sh | bash
        pkg_install jellyfin
        ;;
    dnf|yum)
        rpm -Uvh https://repo.jellyfin.org/jellyfin-repo-10.8.3-1.noarch.rpm
        pkg_install jellyfin
        ;;
    zypper)
        pkg_install jellyfin
        ;;
    pacman)
        pkg_install jellyfin
        ;;
esac

systemctl enable jellyfin
systemctl start jellyfin

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8096/tcp
    ufw allow 8920/tcp
fi

echo
echo "✅ Jellyfin installé avec succès"
echo "URL: http://votre-serveur:8096"
echo "Configuration: /etc/jellyfin"
echo "Bien configurer les chemins d'accès aux médias"
