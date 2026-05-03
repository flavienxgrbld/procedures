#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

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
