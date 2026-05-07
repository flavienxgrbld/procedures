#!/usr/bin/env bash

set -euo pipefail

COMMON_SCRIPT="/tmp/install_common.sh"
if [ ! -f "$COMMON_SCRIPT" ]; then
    curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/install-scripts/main/root/common/install_common.sh" -o "$COMMON_SCRIPT"
fi
source "$COMMON_SCRIPT"

ensure_root
detect_os
detect_package_manager

info "Outline - Wiki collaboratif moderne"

OUTLINE_DIR="/opt/outline"

echo "=== Installation d'Outline ==="
pkg_install docker.io docker-compose

mkdir -p $OUTLINE_DIR
cd $OUTLINE_DIR

# Configuration
cat > docker-compose.yml <<'EOF'
version: '3'

services:
  outline:
    image: outlinewiki/outline:latest
    ports:
      - "3000:3000"
    environment:
      URL: http://localhost:3000
      SECRET_KEY: your-secret-key
      UTILS_SECRET_KEY: your-utils-secret-key
      DATABASE_URL: postgresql://user:password@postgres:5432/outline
      REDIS_URL: redis://redis:6379
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:13
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: outline
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:6-alpine

volumes:
  postgres_data:
EOF

docker-compose up -d

if command -v ufw >/dev/null 2>&1; then
    ufw allow 3000/tcp
fi

echo
echo "✅ Outline en cours d'installation"
echo "URL: http://votre-serveur:3000"
