#!/usr/bin/env bash

set -euo pipefail

# Bibliothèque commune : copie du dépôt en priorité, téléchargement sinon.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/../install_common.sh"
if [ ! -f "$COMMON_SCRIPT" ]; then
    COMMON_SCRIPT="$(mktemp)"
    curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/procedures/main/install_common.sh" -o "$COMMON_SCRIPT"
fi
# shellcheck source=../install_common.sh
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
