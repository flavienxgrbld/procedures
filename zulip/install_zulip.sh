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

info "Zulip - Plateforme de chat avec threads"

echo "=== Installation de Zulip ==="
pkg_install curl

curl https://zulip.com/deployments/next/install | bash -x

if command -v ufw >/dev/null 2>&1; then
    ufw allow 443/tcp
    ufw allow 80/tcp
fi

echo
echo "✅ Zulip en cours d'installation"
echo "Suivez les instructions après l'installation"
echo "URL: https://votre-domaine"
