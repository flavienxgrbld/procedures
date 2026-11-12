#!/usr/bin/env bash
# Installation de Keycloak (image officielle) avec Docker Compose et une base PostgreSQL.
# Mode labo : start-dev, HTTP sur le port 8080. Pour la production, voir « Mode production » du README.
#
# Variables modifiables :
#   KEYCLOAK_VERSION     version de l'image (défaut : 26.8.2)
#   KEYCLOAK_PORT        port publié (défaut : 8080)
#   KEYCLOAK_ADMIN_PASS  mot de passe du compte admin temporaire (défaut : généré)

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

info "Keycloak - Gestion des identités et des accès (SSO)"

APP_DIR="/opt/keycloak"
ensure_docker
mkdir -p "$APP_DIR"
chmod 700 "$APP_DIR"

if [ ! -f "${APP_DIR}/.env" ]; then
    (umask 077; cat > "${APP_DIR}/.env") <<EOF
KEYCLOAK_VERSION=${KEYCLOAK_VERSION:-26.8.2}
KEYCLOAK_PORT=${KEYCLOAK_PORT:-8080}
KC_BOOTSTRAP_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASS:-$(random_password 20)}
DB_PASSWORD=$(random_password 24)
EOF
fi

cat > "${APP_DIR}/compose.yaml" <<'EOF'
services:
  postgres:
    image: postgres:17
    restart: unless-stopped
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - pg_data:/var/lib/postgresql/data

  keycloak:
    image: quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}
    restart: unless-stopped
    command: start-dev
    depends_on: [postgres]
    ports:
      - "${KEYCLOAK_PORT}:8080"
    environment:
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: ${DB_PASSWORD}
      KC_BOOTSTRAP_ADMIN_USERNAME: admin
      KC_BOOTSTRAP_ADMIN_PASSWORD: ${KC_BOOTSTRAP_ADMIN_PASSWORD}

volumes:
  pg_data:
EOF

compose_up "$APP_DIR"
# shellcheck disable=SC1091
. "${APP_DIR}/.env"
open_ports "${KEYCLOAK_PORT}/tcp"

echo
echo "✅ Keycloak ${KEYCLOAK_VERSION} démarré (mode labo, démarrage : environ 1 minute)"
echo "Console : http://$(primary_ip):${KEYCLOAK_PORT}/admin"
echo "Compte temporaire : admin (mot de passe dans ${APP_DIR}/.env) -> créer un vrai administrateur puis le supprimer"
