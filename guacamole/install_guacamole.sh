#!/usr/bin/env bash
# Installation d'Apache Guacamole (passerelle RDP/SSH/VNC dans le navigateur)
# avec Docker Compose : guacd, application web et base MySQL initialisée.
#
# Variables modifiables :
#   GUAC_VERSION  version des images guacamole et guacd (défaut : 1.6.0)
#   GUAC_PORT     port publié (défaut : 8080)

set -euo pipefail

# Bibliothèque commune : copie du dépôt en priorité, téléchargement sinon.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/../install_common.sh"
if [ ! -f "$COMMON_SCRIPT" ]; then
    COMMON_SCRIPT="$(mktemp)"
    curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/procedures/main/install_common.sh" -o "$COMMON_SCRIPT"
fi
# shellcheck source=../install_common.sh
source "$COMMON_SCRIPT"

ensure_root
detect_os
detect_package_manager

info "Apache Guacamole - Accès à distance sans client"

APP_DIR="/opt/guacamole"
GUAC_VERSION="${GUAC_VERSION:-1.6.0}"
GUAC_PORT="${GUAC_PORT:-8080}"

ensure_docker
mkdir -p "${APP_DIR}/init"
chmod 711 "$APP_DIR"   # .env reste en 600 ; init/ doit rester lisible par MySQL

if [ ! -f "${APP_DIR}/.env" ]; then
    (umask 077; cat > "${APP_DIR}/.env") <<EOF
GUAC_VERSION=${GUAC_VERSION}
GUAC_PORT=${GUAC_PORT}
MYSQL_ROOT_PASSWORD=$(random_password 24)
MYSQL_PASSWORD=$(random_password 24)
EOF
fi

if [ ! -s "${APP_DIR}/init/initdb.sql" ]; then
    info "Génération du schéma de la base (initdb.sql fourni par l'image)"
    docker run --rm "guacamole/guacamole:${GUAC_VERSION}" /opt/guacamole/bin/initdb.sh --mysql > "${APP_DIR}/init/initdb.sql"
    chmod 644 "${APP_DIR}/init/initdb.sql"
    [ -s "${APP_DIR}/init/initdb.sql" ] || error_exit "initdb.sql vide : vérifier l'image guacamole/guacamole:${GUAC_VERSION}"
fi

cat > "${APP_DIR}/compose.yaml" <<'EOF'
services:
  guacd:
    image: guacamole/guacd:${GUAC_VERSION}
    restart: unless-stopped

  mysql:
    image: mysql:8.4
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: guacamole
      MYSQL_USER: guacamole
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      # exécuté au premier démarrage seulement (base vide)
      - ./init:/docker-entrypoint-initdb.d:ro
      - mysql_data:/var/lib/mysql

  guacamole:
    image: guacamole/guacamole:${GUAC_VERSION}
    restart: unless-stopped
    depends_on:
      - guacd
      - mysql
    ports:
      - "${GUAC_PORT}:8080"
    environment:
      GUACD_HOSTNAME: guacd
      MYSQL_HOSTNAME: mysql
      MYSQL_DATABASE: guacamole
      MYSQL_USER: guacamole
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}

volumes:
  mysql_data:
EOF

compose_up "$APP_DIR"
open_ports "${GUAC_PORT}/tcp"

echo
echo "✅ Guacamole ${GUAC_VERSION} démarré (initialisation de la base : 1 à 2 minutes)"
echo "Interface : http://$(hostname -I | awk '{print $1}'):${GUAC_PORT}/guacamole"
echo "Compte initial : guacadmin / guacadmin  -> à changer immédiatement"
