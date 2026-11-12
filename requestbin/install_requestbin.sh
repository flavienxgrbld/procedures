#!/usr/bin/env bash
# RequestBin n'existe plus : installation de Webhook.site (équivalent libre) avec Docker Compose.
#
# Variables modifiables :
#   WEBHOOK_URL  adresse utilisée dans le navigateur (défaut : http://<ip>:8084)

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

info "Webhook.site - Capture de requêtes HTTP (remplaçant de RequestBin)"

APP_DIR="/opt/webhook.site"
WEBHOOK_URL="${WEBHOOK_URL:-http://$(primary_ip):8084}"
ensure_docker
pkg_install git
if [ -d "${APP_DIR}/.git" ]; then
    git -C "$APP_DIR" checkout -q -- docker-compose.yml
    git -C "$APP_DIR" pull -q --ff-only
else
    git clone -q --depth 1 https://github.com/webhooksite/webhook.site.git "$APP_DIR"
fi
F="${APP_DIR}/docker-compose.yml"
sed -i -E "s|(- *APP_URL=).*|\1${WEBHOOK_URL}|; s|(- *APP_ENV=).*|\1production|; s|(- *APP_DEBUG=).*|\1false|" "$F"
grep -q "APP_URL=${WEBHOOK_URL}" "$F" || warn "APP_URL introuvable dans docker-compose.yml : le régler à la main"
compose_up "$APP_DIR"
open_ports 8084/tcp

echo
echo "✅ Webhook.site démarré : ${WEBHOOK_URL}"
echo "Une URL unique est générée à l'ouverture de la page ; ne pas y envoyer de vraies données sensibles."
