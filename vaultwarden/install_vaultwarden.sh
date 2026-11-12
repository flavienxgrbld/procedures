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
