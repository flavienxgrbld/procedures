#!/usr/bin/env bash
# Installation de Paperless-ngx avec les fichiers Docker Compose officiels
# (PostgreSQL + Valkey), sans question.
#
# Variables modifiables :
#   PAPERLESS_URL        adresse du site (défaut : http://<ip>:8000)
#   PAPERLESS_OCR        langues de l'OCR (défaut : fra+eng)
#   PAPERLESS_ADMIN      compte administrateur (défaut : admin)
#   PAPERLESS_ADMIN_PASS mot de passe (défaut : généré)

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

info "Paperless-ngx - Archive numérique de documents"

APP_DIR="/opt/paperless"
BASE="https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/main/docker/compose"
PAPERLESS_URL="${PAPERLESS_URL:-http://$(primary_ip):8000}"
PAPERLESS_OCR="${PAPERLESS_OCR:-fra+eng}"
PAPERLESS_ADMIN="${PAPERLESS_ADMIN:-admin}"
PAPERLESS_ADMIN_PASS="${PAPERLESS_ADMIN_PASS:-$(random_password 16)}"

ensure_docker
mkdir -p "${APP_DIR}"/{consume,export}
download_file "${BASE}/docker-compose.postgres.yml" "${APP_DIR}/docker-compose.yml"
[ -f "${APP_DIR}/.env" ] || download_file "${BASE}/.env" "${APP_DIR}/.env"

ENV="${APP_DIR}/docker-compose.env"
if [ ! -f "$ENV" ]; then
    download_file "${BASE}/docker-compose.env" "$ENV"
    set_kv() { if grep -qE "^#?$1=" "$ENV"; then sed -i -E "s|^#?$1=.*|$1=$2|" "$ENV"; else echo "$1=$2" >> "$ENV"; fi; }
    set_kv PAPERLESS_URL "$PAPERLESS_URL"
    set_kv PAPERLESS_SECRET_KEY "$(random_password 50)"
    set_kv PAPERLESS_TIME_ZONE "$(system_tz)"
    set_kv PAPERLESS_OCR_LANGUAGE "$PAPERLESS_OCR"
    set_kv PAPERLESS_OCR_LANGUAGES "$(echo "$PAPERLESS_OCR" | tr '+' ' ' | sed 's/\beng\b//; s/  */ /g; s/^ //; s/ $//')"
    # Compte créé au premier démarrage
    set_kv PAPERLESS_ADMIN_USER "$PAPERLESS_ADMIN"
    set_kv PAPERLESS_ADMIN_PASSWORD "$PAPERLESS_ADMIN_PASS"
    chmod 600 "$ENV"
    NEW=1
else
    info "Configuration existante conservée : ${ENV}"
    NEW=0
fi

compose_up "$APP_DIR"
open_ports 8000/tcp
[ "$NEW" = 1 ] && save_credentials /root/paperless_identifiants.txt "Paperless : ${PAPERLESS_URL}" "Compte : ${PAPERLESS_ADMIN}" "Mot de passe : ${PAPERLESS_ADMIN_PASS}"

echo
echo "✅ Paperless-ngx démarré : ${PAPERLESS_URL} (premier démarrage : 1 à 2 minutes)"
echo "Dossier surveillé : ${APP_DIR}/consume ; identifiants : /root/paperless_identifiants.txt"
echo "Après la première connexion, retirer PAPERLESS_ADMIN_PASSWORD de ${ENV}."
