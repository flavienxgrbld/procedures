#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "LXD - Conteneur et gestion de machines virtuelles"

echo "=== Installation de LXD ==="
case "$PKG_MANAGER" in
    apt)
        pkg_install lxd lxd-client
        ;;
    dnf|yum)
        pkg_install lxd
        ;;
    pacman)
        pkg_install lxd
        ;;
esac

# Initialisation
systemctl enable lxd
systemctl start lxd

# Configuration initiale
lxd init --auto

echo
echo "✅ LXD installé avec succès"
echo "Commandes utiles:"
echo "  lxc launch ubuntu:22.04 test - Créer un conteneur"
echo "  lxc list - Lister les conteneurs"
echo "  lxc shell test - Accéder au conteneur"
