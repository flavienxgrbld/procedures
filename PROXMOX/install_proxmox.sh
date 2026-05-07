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
