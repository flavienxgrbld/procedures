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

info "Pi-hole - Bloqueur de publicités DNS"

echo "=== Installation de Pi-hole ==="
curl -sSL https://install.pi-hole.net | bash

if command -v ufw >/dev/null 2>&1; then
    ufw allow 53/tcp
    ufw allow 53/udp
    ufw allow 80/tcp
    ufw allow 443/tcp
fi

echo
echo "✅ Pi-hole installé avec succès"
echo "URL Web: http://votre-serveur/admin"
echo "DNS: votre-serveur"
echo "Port: 53 (DNS)"
