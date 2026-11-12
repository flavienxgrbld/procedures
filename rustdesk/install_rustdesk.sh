#!/usr/bin/env bash
# Installation du serveur RustDesk (hbbs + hbbr) avec l'image Docker officielle.
#
# Variables :
#   RUSTDESK_HOST  nom ou adresse publique du serveur (défaut : adresse principale)

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

info "RustDesk Server - Prise en main à distance auto-hébergée"

APP_DIR="/opt/rustdesk"
RUSTDESK_HOST="${RUSTDESK_HOST:-$(primary_ip)}"
ensure_docker
mkdir -p "${APP_DIR}/data"
chmod 700 "${APP_DIR}/data"

cat > "${APP_DIR}/compose.yaml" <<EOF
services:
  hbbs:
    container_name: hbbs
    image: rustdesk/rustdesk-server:latest
    command: hbbs -r ${RUSTDESK_HOST}:21117
    ports:
      - "21115:21115"
      - "21116:21116"
      - "21116:21116/udp"
    volumes:
      - ./data:/root
    depends_on: [hbbr]
    restart: unless-stopped

  hbbr:
    container_name: hbbr
    image: rustdesk/rustdesk-server:latest
    command: hbbr
    ports:
      - "21117:21117"
    volumes:
      - ./data:/root
    restart: unless-stopped
EOF
compose_up "$APP_DIR"
open_ports 21115:21117/tcp 21116/udp

info "Attente de la génération des clés"
for _ in $(seq 1 30); do [ -s "${APP_DIR}/data/id_ed25519.pub" ] && break; sleep 1; done

echo
echo "✅ Serveur RustDesk démarré"
echo "Dans chaque client : Paramètres > Réseau > Serveur ID = ${RUSTDESK_HOST}"
if [ -s "${APP_DIR}/data/id_ed25519.pub" ]; then
    echo "Clé = $(cat "${APP_DIR}/data/id_ed25519.pub")"
else
    echo "Clé : sudo cat ${APP_DIR}/data/id_ed25519.pub"
fi
echo "Ne jamais diffuser ${APP_DIR}/data/id_ed25519 (clé privée)."
