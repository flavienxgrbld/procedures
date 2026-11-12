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
