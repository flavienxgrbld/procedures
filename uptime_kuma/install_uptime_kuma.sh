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
