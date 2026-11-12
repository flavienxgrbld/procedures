#!/usr/bin/env bash
# Installation de Home Assistant (méthode « Container ») avec l'image officielle.
#
# Variables modifiables :
#   HA_TZ  fuseau horaire (défaut : celui du système)

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

info "Home Assistant - Domotique locale"

APP_DIR="/opt/homeassistant"
HA_TZ="${HA_TZ:-$(system_tz)}"

ensure_docker
mkdir -p "${APP_DIR}/config"

cat > "${APP_DIR}/compose.yaml" <<EOF
services:
  homeassistant:
    image: ghcr.io/home-assistant/home-assistant:stable
    container_name: homeassistant
    restart: unless-stopped
    privileged: true
    network_mode: host
    environment:
      TZ: ${HA_TZ}
    volumes:
      - ./config:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
EOF

compose_up "$APP_DIR"
# Mode réseau host : le port 8123 est celui de l'hôte, ufw s'applique
open_ports 8123/tcp

echo
echo "✅ Home Assistant démarré (premier lancement : 1 à 2 minutes)"
echo "Assistant : http://$(primary_ip):8123  -> créer le compte propriétaire sans attendre"
echo "Mise à jour : cd ${APP_DIR} && sudo docker compose pull && sudo docker compose up -d"
