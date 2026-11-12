#!/usr/bin/env bash

set -euo pipefail

# Bibliothèque commune : copie du dépôt en priorité, téléchargement sinon.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/../install_common.sh"
if [ ! -f "$COMMON_SCRIPT" ]; then
    COMMON_SCRIPT="$(mktemp)"
    curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/install-scripts/main/root/common/install_common.sh" -o "$COMMON_SCRIPT"
fi
# shellcheck source=../install_common.sh
source "$COMMON_SCRIPT"

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
