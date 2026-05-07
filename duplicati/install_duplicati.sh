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

info "Duplicati - Sauvegarde chiffrée et distribuée"

echo "=== Installation de Duplicati ==="
case "$PKG_MANAGER" in
    apt)
        sudo add-apt-repository ppa:duplicati/duplicati-releases
        pkg_update
        pkg_install duplicati
        ;;
    dnf|yum)
        pkg_install mono-core mono-devel
        cd /opt
        wget https://github.com/duplicati/duplicati/releases/download/v2.0.6.3-2.0_beta_2024-01-22/duplicati-2.0.6.3-2.0_beta_2024-01-22.linux-x64-gtk.tar.gz
        tar -xzf duplicati-*.tar.gz
        rm duplicati-*.tar.gz
        ;;
esac

systemctl enable duplicati
systemctl start duplicati

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8200/tcp
fi

echo
echo "✅ Duplicati en cours d'installation"
echo "URL: http://votre-serveur:8200"
