#!/usr/bin/env bash
# Installation d'Immich avec les fichiers Docker Compose officiels de la dernière version.
#
# Variables modifiables :
#   IMMICH_UPLOAD  dossier des photos et vidéos (défaut : /srv/immich/library)
#   IMMICH_DB      dossier de la base, sur un disque local (défaut : /opt/immich/postgres)
#   IMMICH_TZ      fuseau horaire (défaut : celui du système)

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

info "Immich - Photos et vidéos auto-hébergées"

APP_DIR="/opt/immich"
IMMICH_UPLOAD="${IMMICH_UPLOAD:-/srv/immich/library}"
IMMICH_DB="${IMMICH_DB:-/opt/immich/postgres}"
IMMICH_TZ="${IMMICH_TZ:-$(system_tz)}"

mem_mb=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
[ "$mem_mb" -ge 3800 ] || warn "Mémoire : ${mem_mb} Mo (Immich demande 4 Go minimum, 6 Go conseillés)"

ensure_docker
mkdir -p "$APP_DIR" "$IMMICH_UPLOAD" "$IMMICH_DB"

info "Fichiers officiels de la dernière version"
download_file https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml "${APP_DIR}/docker-compose.yml"

set_env() {  # set_env CLÉ VALEUR : remplace ou ajoute la ligne dans .env
    if grep -qE "^#? *$1=" "${APP_DIR}/.env"; then
        sed -i -E "s|^#? *$1=.*|$1=$2|" "${APP_DIR}/.env"
    else
        echo "$1=$2" >> "${APP_DIR}/.env"
    fi
}

if [ ! -f "${APP_DIR}/.env" ]; then
    download_file https://github.com/immich-app/immich/releases/latest/download/example.env "${APP_DIR}/.env"
    set_env DB_PASSWORD "$(random_password 24)"
else
    info "Fichier .env existant conservé (mot de passe de la base inchangé)"
fi
set_env UPLOAD_LOCATION "$IMMICH_UPLOAD"
set_env DB_DATA_LOCATION "$IMMICH_DB"
set_env TZ "$IMMICH_TZ"
chmod 600 "${APP_DIR}/.env"

info "Démarrage (le premier téléchargement d'images fait plusieurs Go)"
(cd "$APP_DIR" && docker compose pull && docker compose up -d)
open_ports 2283/tcp

echo
echo "✅ Immich démarré"
echo "Créer le compte administrateur sans attendre : http://$(primary_ip):2283"
echo "Photos : ${IMMICH_UPLOAD} — Base : ${IMMICH_DB}"
