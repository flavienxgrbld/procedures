#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

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
