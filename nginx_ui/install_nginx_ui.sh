#!/usr/bin/env bash
# Installation de Nginx UI (interface web d'administration de Nginx) avec l'image
# Docker officielle, qui embarque Nginx.
#
# Variables modifiables :
#   NGINXUI_HTTP / NGINXUI_HTTPS  ports publiés (défaut : 8080 / 8443)

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

info "Nginx UI - Administration de Nginx dans le navigateur"

APP_DIR="/opt/nginx-ui"
NGINXUI_HTTP="${NGINXUI_HTTP:-8080}"
NGINXUI_HTTPS="${NGINXUI_HTTPS:-8443}"
ensure_docker
mkdir -p "${APP_DIR}"/{nginx,nginx-ui,www}

cat > "${APP_DIR}/compose.yaml" <<EOF
services:
  nginx-ui:
    image: uozi/nginx-ui:latest
    container_name: nginx-ui
    restart: unless-stopped
    environment:
      TZ: $(system_tz)
    ports:
      - "${NGINXUI_HTTP}:80"
      - "${NGINXUI_HTTPS}:443"
    volumes:
      - ./nginx:/etc/nginx
      - ./nginx-ui:/etc/nginx-ui     # comptes et réglages de Nginx UI
      - ./www:/var/www
EOF
compose_up "$APP_DIR"
open_ports "${NGINXUI_HTTP}/tcp" "${NGINXUI_HTTPS}/tcp"

echo
echo "✅ Nginx UI démarré : http://$(primary_ip):${NGINXUI_HTTP}"
echo "Créer le compte administrateur sans attendre, puis activer la double authentification."
