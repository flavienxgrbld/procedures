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

info "Redis - Cache et base de données en mémoire"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

echo "=== Installation de Redis ==="
pkg_install redis-server redis-tools

systemctl enable redis-server
systemctl start redis-server

# Configuration sécurité
read -sp "Mot de passe Redis: " REDIS_PASS
echo

# Backup config
cp /etc/redis/redis.conf /etc/redis/redis.conf.bak

# Configuration password
sed -i "s/# requirepass foobared/requirepass ${REDIS_PASS}/" /etc/redis/redis.conf

# Configuration de base
sed -i 's/^# maxmemory <bytes>/maxmemory 256mb/' /etc/redis/redis.conf
sed -i 's/^# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf

systemctl restart redis-server

if command -v ufw >/dev/null 2>&1; then
    ufw allow 6379/tcp
fi

echo
echo "✅ Redis installé avec succès"
echo "Port: 6379"
echo "Configuration: /etc/redis/redis.conf"
