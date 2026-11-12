#!/usr/bin/env bash
# Installation de Focalboard (serveur autonome) avec l'image Docker officielle.
#
# Variables modifiables :
#   FOCALBOARD_PORT  port publié (défaut : 8000)

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

info "Focalboard - Gestion de projets en tableaux"

APP_DIR="/opt/focalboard"
FOCALBOARD_PORT="${FOCALBOARD_PORT:-8000}"

ensure_docker
mkdir -p "$APP_DIR"
cat > "${APP_DIR}/compose.yaml" <<EOF
services:
  focalboard:
    image: mattermost/focalboard:latest
    container_name: focalboard
    restart: unless-stopped
    ports:
      - "${FOCALBOARD_PORT}:8000"
    volumes:
      # Emplacement des données d'après le Dockerfile officiel
      - focalboard_data:/opt/focalboard/data

volumes:
  focalboard_data:
EOF

compose_up "$APP_DIR"
open_ports "${FOCALBOARD_PORT}/tcp"

echo
echo "✅ Focalboard démarré : http://$(hostname -I | awk '{print $1}'):${FOCALBOARD_PORT}"
echo "Première visite : créer son compte avec le lien « Register » (le premier compte n'a pas de droits particuliers)."
