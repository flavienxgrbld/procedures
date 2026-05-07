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

info "Kodi - Centre multimédia personnel"

echo "=== Installation de Kodi ==="
case "$PKG_MANAGER" in
    apt)
        pkg_install software-properties-common
        add-apt-repository ppa:team-xbmc/ppa
        pkg_update
        pkg_install kodi
        ;;
    dnf|yum)
        pkg_install kodi
        ;;
    pacman)
        pkg_install kodi
        ;;
esac

echo
echo "✅ Kodi installé avec succès"
echo "Lancez avec: kodi"
echo "* Cette installation est plus adaptée pour les clients qu'aux serveurs"
