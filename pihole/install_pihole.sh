#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

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
