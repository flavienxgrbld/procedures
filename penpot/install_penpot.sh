#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Penpot - Plateforme de design collaborative"

echo "=== Installation de Penpot ==="
pkg_install docker.io docker-compose

docker pull penpotapp/penpot:latest

mkdir -p /opt/penpot
cd /opt/penpot

cat > docker-compose.yml <<'EOF'
version: '3'

services:
  penpot:
    image: penpotapp/penpot:latest
    ports:
      - "80:80"
    environment:
      - PENPOT_FLAG_REGISTRATION_DISABLED=false
      - PENPOT_FLAG_DEMO_USERS=false
    volumes:
      - penpot_data:/data

volumes:
  penpot_data:
EOF

docker-compose up -d

if command -v ufw >/dev/null 2>&1; then
    ufw allow 80/tcp
fi

echo
echo "✅ Penpot en cours d'installation"
echo "URL: http://votre-serveur"
