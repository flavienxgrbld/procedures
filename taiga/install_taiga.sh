#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Taiga - Plateforme de gestion de projets"

TAIGA_DIR="/opt/taiga"
TAIGA_USER="taiga"

echo "=== Installation de Taiga ==="
pkg_install python3 python3-dev python3-pip postgresql postgresql-client redis-server

# Création utilisateur
if ! id "$TAIGA_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -m -d "$TAIGA_DIR" -c "Taiga Service" "$TAIGA_USER"
fi

mkdir -p $TAIGA_DIR
cd $TAIGA_DIR

# Installation via Docker
pkg_install docker.io docker-compose

cat > docker-compose.yml <<'EOF'
version: '3'

services:
  db:
    image: postgres:14
    environment:
      POSTGRES_DB: taiga
      POSTGRES_USER: taiga
      POSTGRES_PASSWORD: taiga
    volumes:
      - taiga_db:/var/lib/postgresql/data

  taiga:
    image: taigaio/taiga:latest
    ports:
      - "8000:8000"
    environment:
      DEBUG: "False"
      SECRET_KEY: "your-secret-key"
      DB_HOST: db
      DB_NAME: taiga
      DB_USER: taiga
      DB_PASSWORD: taiga
    depends_on:
      - db
    volumes:
      - taiga_media:/taiga/media

volumes:
  taiga_db:
  taiga_media:
EOF

docker-compose up -d

echo
echo "✅ Taiga en cours d'installation"
echo "URL: http://votre-serveur:8000"
