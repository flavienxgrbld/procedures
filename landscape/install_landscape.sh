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

info "Ubuntu Landscape - Gestion de machines Ubuntu"

echo "=== Installation de Landscape ==="
case "$PKG_MANAGER" in
    apt)
        pkg_install software-properties-common
        add-apt-repository ppa:landscape/self-hosted-16.04
        pkg_update
        pkg_install landscape-server
        ;;
    *)
        echo "❌ Landscape n'est disponible que pour Debian/Ubuntu"
        exit 1
        ;;
esac

systemctl enable landscape-server
systemctl start landscape-server

if command -v ufw >/dev/null 2>&1; then
    ufw allow 443/tcp
fi

echo
echo "✅ Landscape en cours d'installation"
echo "URL: https://votre-serveur"
