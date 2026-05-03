#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Immich - Gallerie photos et vidéos"

echo "=== Installation d'Immich ==="
pkg_install docker.io docker-compose

docker pull ghcr.io/immich-app/immich-server:latest

mkdir -p /opt/immich/data

cat > /opt/immich/docker-compose.yml <<'EOF'
version: '3.8'

services:
  immich-server:
    image: ghcr.io/immich-app/immich-server:latest
    ports:
      - "3001:3001"
    environment:
      - DB_HOSTNAME=db
      - DB_USERNAME=postgres
      - DB_PASSWORD=postgres
      - DB_NAME=immich
    volumes:
      - ./data:/usr/src/app/upload
    depends_on:
      - db

  db:
    image: postgres:15
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=immich
    volumes:
      - ./db:/var/lib/postgresql/data
EOF

cd /opt/immich
docker-compose up -d

if command -v ufw >/dev/null 2>&1; then
    ufw allow 3001/tcp
fi

echo
echo "✅ Immich en cours d'installation"
echo "URL: http://votre-serveur:3001"
