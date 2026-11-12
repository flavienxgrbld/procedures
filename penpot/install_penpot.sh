#!/usr/bin/env bash
# Installation de Penpot avec le fichier Docker Compose officiel.
#
# Variables modifiables :
#   PENPOT_URL  adresse utilisée dans le navigateur (défaut : http://<ip>:9001)

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

info "Penpot - Design d'interfaces et prototypage"

APP_DIR="/opt/penpot"
PENPOT_URL="${PENPOT_URL:-http://$(primary_ip):9001}"
ensure_docker
mkdir -p "$APP_DIR"
download_file https://raw.githubusercontent.com/penpot/penpot/main/docker/images/docker-compose.yaml "${APP_DIR}/docker-compose.yaml"
sed -i -E "s|^(\s*PENPOT_PUBLIC_URI:).*|\1 ${PENPOT_URL}|" "${APP_DIR}/docker-compose.yaml"
grep -q "PENPOT_PUBLIC_URI: ${PENPOT_URL}" "${APP_DIR}/docker-compose.yaml" || warn "PENPOT_PUBLIC_URI introuvable dans le fichier officiel : le régler à la main"

(cd "$APP_DIR" && docker compose -p penpot -f docker-compose.yaml pull && docker compose -p penpot -f docker-compose.yaml up -d)
open_ports 9001/tcp

echo
echo "✅ Penpot démarré : ${PENPOT_URL}"
echo "Créer les comptes de l'équipe, puis ajouter disable-registration à PENPOT_FLAGS (voir le README)."
