#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

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
