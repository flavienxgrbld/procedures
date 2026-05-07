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

info "Woodpecker CI - Pipeline CI/CD décentralisée"

echo "=== Installation de Woodpecker CI ==="
pkg_install docker.io curl

# Service docker
systemctl enable docker
systemctl start docker

# Création répertoires
mkdir -p /var/lib/woodpecker
chmod 755 /var/lib/woodpecker

# Installation Woodpecker Server
docker volume create woodpecker-server-data

docker run -d \
  -p 8000:8000 \
  -p 9000:9000 \
  --name woodpecker-server \
  --restart always \
  -e WOODPECKER_OPEN=true \
  -v woodpecker-server-data:/data \
  -v /var/run/docker.sock:/var/run/docker.sock \
  woodpeckerci/woodpecker-server:latest

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8000/tcp
fi

echo
echo "✅ Woodpecker CI en cours d'installation"
echo "URL: http://votre-serveur:8000"
echo "Vous devez enregistrer des runners: woodpecker-agent"
