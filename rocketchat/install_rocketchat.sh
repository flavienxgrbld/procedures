#!/usr/bin/env bash
# Installation de Rocket.Chat avec le dépôt officiel rocketchat-compose (sans proxy, port 3000).
#
# Variables modifiables :
#   RC_ROOT_URL  adresse utilisée dans le navigateur (défaut : http://<ip>:3000)
#   RC_RELEASE   version de Rocket.Chat (défaut : celle du fichier .env.example officiel)

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

info "Rocket.Chat - Messagerie d'équipe"

APP_DIR="/opt/rocketchat-compose"
RC_ROOT_URL="${RC_ROOT_URL:-http://$(primary_ip):3000}"
ensure_docker
pkg_install git
if [ -d "${APP_DIR}/.git" ]; then
    git -C "$APP_DIR" pull -q --ff-only
else
    git clone -q --depth 1 https://github.com/RocketChat/rocketchat-compose.git "$APP_DIR"
fi
cd "$APP_DIR"
[ -f .env ] || cp .env.example .env
set_env() { if grep -qE "^#? *$1=" .env; then sed -i -E "s|^#? *$1=.*|$1=$2|" .env; else echo "$1=$2" >> .env; fi; }
set_env ROOT_URL "$RC_ROOT_URL"
[ -n "${RC_RELEASE:-}" ] && set_env RELEASE "$RC_RELEASE"
chmod 600 .env

docker compose -f compose.database.yml -f compose.yml pull
docker compose -f compose.database.yml -f compose.yml up -d
open_ports 3000/tcp

echo
echo "✅ Rocket.Chat démarré (version $(sed -nE 's/^RELEASE=//p' .env)) : ${RC_ROOT_URL}"
echo "L'assistant crée le compte administrateur à la première visite : le faire sans attendre."
