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

info "Nginx UI - Interface de gestion Nginx"

echo "=== Installation de Nginx UI ==="
pkg_install docker.io

docker run -d \
  -p 8080:80 \
  -p 8443:443 \
  --name nginx-ui \
  --restart=always \
  -v nginx_config:/etc/nginx \
  -v nginx_data:/var/www \
  uozi/nginx-ui:latest

docker volume create nginx_config
docker volume create nginx_data

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8080/tcp
    ufw allow 8443/tcp
fi

echo
echo "✅ Nginx UI en cours d'installation"
echo "URL: http://votre-serveur:8080"
