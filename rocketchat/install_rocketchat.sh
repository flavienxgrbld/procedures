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

info "Rocket.Chat - Plateforme de messagerie collaborative"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

# Installation dépendances
pkg_install curl wget gnupg

# Installation Docker (si pas déjà installé)
if ! command -v docker >/dev/null 2>&1; then
    echo "=== Installation de Docker ==="
    bash "$SCRIPT_DIR/../infrastructure/install_docker.sh"
fi

echo "=== Installation de Rocket.Chat ==="
mkdir -p /opt/rocketchat
cd /opt/rocketchat

# Docker Compose pour Rocket.Chat
cat > docker-compose.yml <<'EOF'
version: '3.8'
services:
  rocketchat:
    image: rocket.chat:latest
    restart: always
    ports:
      - "3000:3000"
    environment:
      MONGO_URL: mongodb://mongo:27017/rocketchat
      MONGO_OPLOG_URL: mongodb://mongo:27017/local
      ROOT_URL: http://localhost:3000
    depends_on:
      - mongo

  mongo:
    image: mongo:5.0
    restart: always
    volumes:
      - mongo_data:/data/db
    command: mongod --oplogSize 128 --replSet rs0 --storageEngine wiredTiger

  mongo-init:
    image: mongo:5.0
    command: >
      mongosh --host mongo:27017 --eval
      "rs.initiate({ _id: 'rs0', members: [ { _id: 0, host: 'mongo:27017' } ] })"
    depends_on:
      - mongo

volumes:
  mongo_data:
EOF

docker-compose up -d

echo
echo "✅ Rocket.Chat installé avec succès"
echo "URL: http://votre-serveur:3000"
echo "Admin par défaut: /admin/users"
