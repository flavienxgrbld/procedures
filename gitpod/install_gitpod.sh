#!/usr/bin/env bash
# Gitpod auto-hébergé n'est plus distribué : ce script installe à la place
# OpenVSCode Server (VS Code dans le navigateur, publié par l'équipe Gitpod)
# avec l'image Docker officielle, protégé par un jeton de connexion.
#
# Variables modifiables :
#   OVS_PORT   port publié (défaut : 3000)
#   OVS_TOKEN  jeton de connexion (défaut : généré)

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

info "OpenVSCode Server (remplaçant de Gitpod auto-hébergé)"

APP_DIR="/opt/openvscode"
OVS_PORT="${OVS_PORT:-3000}"

ensure_docker
mkdir -p "${APP_DIR}/workspace"
chown -R 1000:1000 "${APP_DIR}/workspace"

if [ ! -f "${APP_DIR}/.env" ]; then
    (umask 077; printf 'OVS_PORT=%s\nOVS_TOKEN=%s\n' "$OVS_PORT" "${OVS_TOKEN:-$(random_password 32)}" > "${APP_DIR}/.env")
fi

cat > "${APP_DIR}/compose.yaml" <<'EOF'
services:
  openvscode:
    image: gitpod/openvscode-server:latest
    container_name: openvscode
    restart: unless-stopped
    ports:
      - "${OVS_PORT}:3000"
    command: --host 0.0.0.0 --connection-token ${OVS_TOKEN}
    volumes:
      - ./workspace:/home/workspace
EOF

compose_up "$APP_DIR"
# shellcheck disable=SC1091
. "${APP_DIR}/.env"
open_ports "${OVS_PORT}/tcp"

echo
echo "✅ OpenVSCode Server démarré"
echo "Adresse : http://$(hostname -I | awk '{print $1}'):${OVS_PORT}/?tkn=<jeton>  (jeton dans ${APP_DIR}/.env)"
echo "Fichiers : ${APP_DIR}/workspace"
