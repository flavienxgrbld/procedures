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

info "Focalboard - Tableau blanc collaboratif"

echo "=== Installation de Focalboard ==="
pkg_install docker.io

docker run -d \
  -p 8000:8000 \
  --name focalboard \
  --restart=always \
  -v focalboard_data:/data \
  mattermost/focalboard:latest

docker volume create focalboard_data

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8000/tcp
fi

echo
echo "✅ Focalboard en cours d'installation"
echo "URL: http://votre-serveur:8000"
echo "Identifiant par défaut: admin@example.com / Password1!"
