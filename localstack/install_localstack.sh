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

info "LocalStack - AWS emulator local"

echo "=== Installation de LocalStack ==="
pkg_install python3 python3-pip docker.io

pip3 install localstack

# Service Docker
systemctl enable docker
systemctl start docker

# Démarrage
docker run -d \
  -p 4566:4566 \
  -p 4571:4571 \
  -e DEBUG=1 \
  --name localstack \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  localstack/localstack:latest

if command -v ufw >/dev/null 2>&1; then
    ufw allow 4566/tcp
fi

echo
echo "✅ LocalStack en cours d'installation"
echo "Accès AWS: http://votre-serveur:4566"
echo "Configuration: awslocal"
