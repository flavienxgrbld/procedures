#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Uptime Kuma - Surveillance de services web"

UPTIMEKUMA_DIR="/opt/uptime-kuma"
UPTIMEKUMA_USER="uptimekuma"

echo "=== Installation d'Uptime Kuma ==="

# Création utilisateur
if ! id "$UPTIMEKUMA_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -m -d "$UPTIMEKUMA_DIR" -c "Uptime Kuma Service" "$UPTIMEKUMA_USER"
fi

mkdir -p $UPTIMEKUMA_DIR
cd $UPTIMEKUMA_DIR

# Installation Docker
pkg_install docker.io

docker run -d \
  -p 3001:3001 \
  --name uptime-kuma \
  --restart=always \
  -v $UPTIMEKUMA_DIR/data:/app/data \
  louislam/uptime-kuma:latest

if command -v ufw >/dev/null 2>&1; then
    ufw allow 3001/tcp
fi

echo
echo "✅ Uptime Kuma en cours d'installation"
echo "URL: http://votre-serveur:3001"
echo "Créez un compte administrateur au premier accès"
