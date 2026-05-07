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
