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

info "Apache Guacamole - Accès aux bureaux RDP/SSH/VNC"

GUACAMOLE_DIR="/opt/guacamole"

echo "=== Installation d'Apache Guacamole ==="
pkg_install docker.io docker-compose

mkdir -p $GUACAMOLE_DIR
cd $GUACAMOLE_DIR

# Docker Compose
cat > docker-compose.yml <<'EOF'
version: '3'

services:
  guacamole:
    image: guacamole/guacamole:latest
    ports:
      - "8080:8080"
    environment:
      GUACD_HOSTNAME: guacd
      MYSQL_HOSTNAME: mysql
      MYSQL_DATABASE: guacamole
      MYSQL_USER: guacamole
      MYSQL_PASSWORD: guacamole
    depends_on:
      - guacd
      - mysql

  guacd:
    image: guacamole/guacd:latest

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: guacamole
      MYSQL_USER: guacamole
      MYSQL_PASSWORD: guacamole
    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  mysql_data:
EOF

docker-compose up -d

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8080/tcp
fi

echo
echo "✅ Apache Guacamole en cours d'installation"
echo "URL: http://votre-serveur:8080/guacamole"
echo "Identifiant par défaut: guacadmin / guacadmin"
