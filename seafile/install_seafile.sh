#!/usr/bin/env bash
# Installation de Seafile 13 (édition Community) avec les fichiers Docker Compose officiels :
# Seafile, MariaDB, Redis, Caddy (HTTPS automatique) et SeaDoc.
#
# Variables :
#   SEAFILE_HOST         nom de domaine (HTTPS) ou adresse IP (HTTP) (défaut : adresse IP, HTTP)
#   SEAFILE_ADMIN_EMAIL  compte administrateur (défaut : admin@exemple.local)

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

info "Seafile - Synchronisation et partage de fichiers"

APP_DIR="/opt/seafile"
BASE="https://manual.seafile.com/13.0/repo/docker"
SEAFILE_HOST="${SEAFILE_HOST:-$(primary_ip)}"
SEAFILE_ADMIN_EMAIL="${SEAFILE_ADMIN_EMAIL:-admin@exemple.local}"
if [[ "$SEAFILE_HOST" =~ ^[0-9.]+$ ]]; then PROTO=http; else PROTO=https; fi

ensure_docker
pkg_install openssl
mkdir -p "$APP_DIR"; chmod 700 "$APP_DIR"
cd "$APP_DIR"
for f in ce/seafile-server.yml seadoc.yml caddy.yml; do download_file "${BASE}/${f}" "${APP_DIR}/$(basename "$f")"; done

if [ ! -f .env ]; then
    download_file "${BASE}/ce/env" .env
    ADMIN_PASS="$(random_password 16)"
    set_env() { if grep -qE "^#? *$1=" .env; then sed -i -E "s|^#? *$1=.*|$1=$2|" .env; else echo "$1=$2" >> .env; fi; }
    set_env SEAFILE_SERVER_HOSTNAME "$SEAFILE_HOST"
    set_env SEAFILE_SERVER_PROTOCOL "$PROTO"
    set_env TIME_ZONE "$(system_tz)"
    set_env JWT_PRIVATE_KEY "$(openssl rand -hex 40)"
    set_env SEAFILE_MYSQL_DB_PASSWORD "$(random_password 24)"
    set_env INIT_SEAFILE_MYSQL_ROOT_PASSWORD "$(random_password 24)"
    set_env INIT_SEAFILE_ADMIN_EMAIL "$SEAFILE_ADMIN_EMAIL"
    set_env INIT_SEAFILE_ADMIN_PASSWORD "$ADMIN_PASS"
    chmod 600 .env
    save_credentials /root/seafile_identifiants.txt "Seafile : ${PROTO}://${SEAFILE_HOST}" "Compte : ${SEAFILE_ADMIN_EMAIL}" "Mot de passe : ${ADMIN_PASS}"
else
    info "Configuration existante conservée : ${APP_DIR}/.env"
fi

docker compose pull
docker compose up -d
open_ports 80/tcp 443/tcp

echo
echo "✅ Seafile démarré : ${PROTO}://${SEAFILE_HOST} (initialisation : 1 à 2 minutes)"
echo "Compte administrateur : /root/seafile_identifiants.txt"
