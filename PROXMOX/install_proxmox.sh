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

info "Proxmox VE - Hyperviseur d'infrastructure virtualisée"

echo "=== Installation de Proxmox VE ==="
echo "⚠️  Proxmox VE nécessite une installation OS dédiée"
echo ""
echo "Pour installer Proxmox VE:"
echo "1. Téléchargez l'ISO depuis https://www.proxmox.com/proxmox-ve/download"
echo "2. Installez Proxmox VE sur un serveur nu"
echo "3. Accédez via https://serveur:8006"
echo ""
echo "Systèmes supportés:"
echo "  - Debian 12 (Bookworm)"
echo "  - Pas d'installation sur OS existant"
