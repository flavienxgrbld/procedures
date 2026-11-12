#!/usr/bin/env bash
# Installation d'Etherpad avec l'image Docker officielle et une base PostgreSQL.
#
# Variables modifiables :
#   ETHERPAD_TITLE       titre de l'instance (défaut : Etherpad)
#   ETHERPAD_ADMIN_PASS  mot de passe du compte admin (défaut : généré)
#   ETHERPAD_PORT        port publié (défaut : 9001)

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

info "Etherpad - Éditeur de texte collaboratif"

APP_DIR="/opt/etherpad"
ETHERPAD_TITLE="${ETHERPAD_TITLE:-Etherpad}"
ETHERPAD_PORT="${ETHERPAD_PORT:-9001}"

ensure_docker
mkdir -p "$APP_DIR"
chmod 700 "$APP_DIR"

# Les mots de passe sont conservés d'une exécution à l'autre (.env)
if [ -f "${APP_DIR}/.env" ]; then
    info "Configuration existante conservée : ${APP_DIR}/.env"
else
    (umask 077; cat > "${APP_DIR}/.env") <<EOF
ETHERPAD_TITLE=${ETHERPAD_TITLE}
ETHERPAD_PORT=${ETHERPAD_PORT}
ADMIN_PASSWORD=${ETHERPAD_ADMIN_PASS:-$(random_password 20)}
DB_PASS=$(random_password 24)
EOF
fi

cat > "${APP_DIR}/compose.yaml" <<'EOF'
services:
  etherpad:
    image: etherpad/etherpad:latest
    container_name: etherpad
    restart: unless-stopped
    depends_on:
      - postgres
    ports:
      - "${ETHERPAD_PORT}:9001"
    environment:
      TITLE: "${ETHERPAD_TITLE}"
      ADMIN_PASSWORD: "${ADMIN_PASSWORD}"
      DB_TYPE: postgres
      DB_HOST: postgres
      DB_PORT: "5432"
      DB_NAME: etherpad
      DB_USER: etherpad
      DB_PASS: "${DB_PASS}"
      TRUST_PROXY: "true"
    volumes:
      - etherpad_var:/opt/etherpad-lite/var

  postgres:
    image: postgres:17
    container_name: etherpad-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: etherpad
      POSTGRES_USER: etherpad
      POSTGRES_PASSWORD: "${DB_PASS}"
    volumes:
      - etherpad_db:/var/lib/postgresql/data

volumes:
  etherpad_var:
  etherpad_db:
EOF

compose_up "$APP_DIR"
open_ports "${ETHERPAD_PORT}/tcp"

# shellcheck disable=SC1091
. "${APP_DIR}/.env"
IP="$(hostname -I | awk '{print $1}')"
echo
echo "✅ Etherpad démarré"
echo "Pads           : http://${IP}:${ETHERPAD_PORT}"
echo "Administration : http://${IP}:${ETHERPAD_PORT}/admin (compte admin, mot de passe dans ${APP_DIR}/.env)"
