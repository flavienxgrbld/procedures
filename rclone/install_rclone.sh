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

info "Rclone - Outil de synchronisation cloud"

echo "=== Installation de Rclone ==="
pkg_install fuse

# Installation
curl https://rclone.org/install.sh | bash

# Configuration
mkdir -p ~/.config/rclone

echo
echo "✅ Rclone installé avec succès"
echo "Configurez avec: rclone config"
echo "Commandes utiles:"
echo "  rclone sync /source /destination"
echo "  rclone mount remote: /mount"
