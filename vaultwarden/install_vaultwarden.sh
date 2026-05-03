#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Vaultwarden - Gestionnaire de mots de passe"

VAULTWARDEN_DIR="/opt/vaultwarden"
VAULTWARDEN_USER="vaultwarden"

echo "=== Installation de Vaultwarden ==="
pkg_install docker.io

docker volume create vaultwarden

docker run -d \
  -p 80:80 \
  -p 443:443 \
  --name vaultwarden \
  --restart=always \
  -e DOMAIN=https://votre-domaine.com \
  -v $VAULTWARDEN_DIR/data:/data \
  vaultwarden/server:latest

if command -v ufw >/dev/null 2>&1; then
    ufw allow 80/tcp
    ufw allow 443/tcp
fi

echo
echo "✅ Vaultwarden en cours d'installation"
echo "URL: https://votre-domaine.com"
echo "Configurez les certificats SSL"
