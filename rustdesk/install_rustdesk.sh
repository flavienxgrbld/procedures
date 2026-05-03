#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Rustdesk - Logiciel de bureaux distants"

RUSTDESK_DIR="/opt/rustdesk"

echo "=== Installation de Rustdesk serveur ==="
pkg_install curl

docker pull rustdesk/rustdesk-server

docker volume create rustdesk-db

docker run -d \
  -p 21115:21115 \
  -p 21116:21116 \
  -p 21116:21116/udp \
  -p 21117:21117 \
  -p 8000:8000 \
  --name rustdesk-server \
  --restart=always \
  -v rustdesk-db:/root \
  rustdesk/rustdesk-server:latest

if command -v ufw >/dev/null 2>&1; then
    ufw allow 21115:21117/tcp
    ufw allow 21116/udp
    ufw allow 8000/tcp
fi

echo
echo "✅ Rustdesk serveur en cours d'installation"
echo "Ports: 21115-21117/tcp, 21116/udp, 8000/tcp"
echo "Conseil oui oui!"
