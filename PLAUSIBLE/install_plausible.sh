#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Plausible Analytics - Analytics respectueux de la vie privée"

PLAUSIBLE_DIR="/opt/plausible"
PLAUSIBLE_USER="plausible"

echo "=== Installation de Plausible Analytics ==="
pkg_install docker.io docker-compose curl postgresql

# Création utilisateur
if ! id "$PLAUSIBLE_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -m -d "$PLAUSIBLE_DIR" -c "Plausible Service" "$PLAUSIBLE_USER"
fi

mkdir -p "$PLAUSIBLE_DIR"
cd "$PLAUSIBLE_DIR"

# Docker Compose
cat > docker-compose.yml <<'EOF'
version: '3.3'

services:
  plausible:
    image: plausible/analytics:latest
    restart: always
    ports:
      - "8000:8000"
    environment:
      - BASE_URL=http://localhost:8000
      - SECRET_KEY_BASE=CHANGE_ME
      - DATABASE_URL=postgresql://plausible:plausible@postgres/plausible_db
      - CLICKHOUSE_DATABASE_URL=http://clickhouse:8123/plausible
    depends_on:
      - postgres
      - clickhouse

  postgres:
    image: postgres:13
    restart: always
    volumes:
      - db:/var/lib/postgresql/data
    environment:
      - POSTGRES_PASSWORD=plausible
      - POSTGRES_USER=plausible
      - POSTGRES_DB=plausible_db

  clickhouse:
    image: clickhouse/clickhouse-server:latest
    restart: always
    volumes:
      - clickhouse:/var/lib/clickhouse

volumes:
  db:
  clickhouse:
EOF

docker-compose up -d

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8000/tcp
fi

echo
echo "✅ Plausible Analytics en cours d'installation"
echo "URL: http://votre-serveur:8000"
echo "Changez BASE_URL et SECRET_KEY_BASE en production"
