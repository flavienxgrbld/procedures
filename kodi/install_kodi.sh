#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

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
