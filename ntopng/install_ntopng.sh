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

info "Ntopng - Moniteur de trafic réseau"

echo "=== Installation de ntopng ==="
pkg_install ntopng ntopngd

# Service
systemctl enable ntopng
systemctl start ntopng

if command -v ufw >/dev/null 2>&1; then
    ufw allow 3000/tcp
fi

echo
echo "✅ ntopng en cours d'installation"
echo "URL: http://votre-serveur:3000"
echo "Identifiant par défaut: admin / admin"
