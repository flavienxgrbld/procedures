#!/usr/bin/env bash
# Installation de Taiga avec le dépôt officiel taiga-docker (branche stable),
# secrets générés et super-utilisateur créé sans question.
#
# Variables modifiables :
#   TAIGA_DOMAIN      adresse:port utilisée dans le navigateur (défaut : <ip>:9000)
#   TAIGA_ADMIN_EMAIL e-mail du super-utilisateur (défaut : admin@exemple.local)

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

info "Taiga - Gestion de projets agiles"

APP_DIR="/opt/taiga-docker"
TAIGA_DOMAIN="${TAIGA_DOMAIN:-$(primary_ip):9000}"
TAIGA_ADMIN_EMAIL="${TAIGA_ADMIN_EMAIL:-admin@exemple.local}"
ensure_docker
pkg_install git openssl
if [ -d "${APP_DIR}/.git" ]; then
    git -C "$APP_DIR" pull -q --ff-only
else
    git clone -q --branch stable https://github.com/taigaio/taiga-docker.git "$APP_DIR"
fi
cd "$APP_DIR"

if [ ! -f .configured ]; then
    set_env() { if grep -qE "^$1=" .env; then sed -i -E "s|^$1=.*|$1=$2|" .env; else echo "$1=$2" >> .env; fi; }
    set_env TAIGA_SCHEME http
    set_env TAIGA_DOMAIN "$TAIGA_DOMAIN"
    set_env WEBSOCKETS_SCHEME ws
    set_env SECRET_KEY "\"$(openssl rand -hex 32)\""
    set_env POSTGRES_PASSWORD "$(random_password 24)"
    set_env RABBITMQ_PASS "$(random_password 24)"
    set_env RABBITMQ_ERLANG_COOKIE "$(random_password 32)"
    set_env EMAIL_BACKEND console
    chmod 600 .env
    touch .configured
fi

docker compose -f docker-compose.yml pull
./launch-taiga.sh
open_ports 9000/tcp

if [ ! -f .admin_created ]; then
    info "Attente de taiga-back puis création du super-utilisateur"
    sleep 30
    ADMIN_PASS="$(random_password 16)"
    docker compose -f docker-compose.yml -f docker-compose-inits.yml run --rm \
        -e DJANGO_SUPERUSER_PASSWORD="$ADMIN_PASS" taiga-manage \
        createsuperuser --noinput --username admin --email "$TAIGA_ADMIN_EMAIL"
    touch .admin_created
    save_credentials /root/taiga_identifiants.txt "Taiga : http://${TAIGA_DOMAIN}" "Compte : admin" "Mot de passe : ${ADMIN_PASS}"
fi

echo
echo "✅ Taiga démarré : http://${TAIGA_DOMAIN} (identifiants : /root/taiga_identifiants.txt)"
echo "E-mails désactivés (EMAIL_BACKEND=console) : configurer EMAIL_* dans ${APP_DIR}/.env pour les invitations."
