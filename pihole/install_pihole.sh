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
