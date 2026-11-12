#!/usr/bin/env bash
# Installation de Plausible Community Edition avec le dépôt officiel plausible/community-edition.
#
# Variables :
#   PLAUSIBLE_URL      adresse publique, ex. https://stats.exemple.fr (obligatoire)
#   PLAUSIBLE_VERSION  branche du dépôt (défaut : v3.2.1)
#   PLAUSIBLE_TLS      oui (défaut avec https://) : Plausible publie 80/443 et obtient lui-même le
#                      certificat ; non : publication sur 127.0.0.1:8000 derrière un proxy

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

info "Plausible CE - Mesure d'audience respectueuse de la vie privée"

APP_DIR="/opt/plausible-ce"
PLAUSIBLE_VERSION="${PLAUSIBLE_VERSION:-v3.2.1}"
[ -n "${PLAUSIBLE_URL:-}" ] || [ -f "${APP_DIR}/.env" ] || error_exit "Définir PLAUSIBLE_URL (ex. https://stats.exemple.fr)"
case "${PLAUSIBLE_URL:-}" in https://*) DEF_TLS=oui ;; *) DEF_TLS=non ;; esac
PLAUSIBLE_TLS="${PLAUSIBLE_TLS:-$DEF_TLS}"

ensure_docker
pkg_install git openssl
if [ -d "${APP_DIR}/.git" ]; then
    git -C "$APP_DIR" fetch -q --depth 1 origin "$PLAUSIBLE_VERSION"
    git -C "$APP_DIR" checkout -q FETCH_HEAD
else
    git clone -q -b "$PLAUSIBLE_VERSION" --single-branch https://github.com/plausible/community-edition "$APP_DIR"
fi
cd "$APP_DIR"

if [ ! -f .env ]; then
    {
        echo "BASE_URL=${PLAUSIBLE_URL}"
        echo "SECRET_KEY_BASE=$(openssl rand -base64 48)"
        if [ "$PLAUSIBLE_TLS" = "oui" ]; then
            echo "HTTP_PORT=80"
            echo "HTTPS_PORT=443"
        else
            echo "HTTP_PORT=8000"
        fi
    } > .env
    chmod 600 .env
fi

if [ "$PLAUSIBLE_TLS" = "oui" ]; then
    printf 'services:\n  plausible:\n    ports:\n      - 80:80\n      - 443:443\n' > compose.override.yml
    open_ports 80/tcp 443/tcp
else
    printf 'services:\n  plausible:\n    ports:\n      - 127.0.0.1:8000:8000\n' > compose.override.yml
fi

docker compose pull
docker compose up -d

echo
echo "✅ Plausible ${PLAUSIBLE_VERSION} démarré : $(sed -n 's/^BASE_URL=//p' .env)"
[ "$PLAUSIBLE_TLS" = "oui" ] || echo "Publier 127.0.0.1:8000 derrière un proxy HTTPS (Nginx + certbot)."
echo "Créer le compte administrateur dès la première visite."
