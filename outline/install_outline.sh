#!/usr/bin/env bash
# Installation d'Outline (wiki d'équipe) avec Docker Compose : Outline, PostgreSQL, Redis,
# stockage local des fichiers et connexion par lien magique envoyé par e-mail.
#
# Variables :
#   OUTLINE_URL    adresse publique en HTTPS, ex. https://wiki.exemple.fr (obligatoire)
#   SMTP_HOST, SMTP_PORT (défaut 587), SMTP_USERNAME, SMTP_PASSWORD, SMTP_FROM_EMAIL (obligatoires)

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

info "Outline - Base de connaissances d'équipe"

APP_DIR="/opt/outline"
if [ ! -f "${APP_DIR}/.env" ]; then
    for v in OUTLINE_URL SMTP_HOST SMTP_USERNAME SMTP_PASSWORD SMTP_FROM_EMAIL; do
        [ -n "${!v:-}" ] || error_exit "Variable manquante : $v (la connexion se fait par e-mail, voir le README)"
    done
fi

ensure_docker
pkg_install openssl
mkdir -p "${APP_DIR}/data"
chown 1001:1001 "${APP_DIR}/data"
chmod 711 "$APP_DIR"

if [ ! -f "${APP_DIR}/.env" ]; then
    DB_PASS="$(random_password 24)"
    (umask 077; cat > "${APP_DIR}/.env") <<EOF
NODE_ENV=production
URL=${OUTLINE_URL}
PORT=3000
SECRET_KEY=$(openssl rand -hex 32)
UTILS_SECRET=$(openssl rand -hex 32)
POSTGRES_PASSWORD=${DB_PASS}
DATABASE_URL=postgres://outline:${DB_PASS}@postgres:5432/outline
PGSSLMODE=disable
REDIS_URL=redis://redis:6379
FILE_STORAGE=local
FILE_STORAGE_LOCAL_ROOT_DIR=/var/lib/outline/data
SMTP_HOST=${SMTP_HOST}
SMTP_PORT=${SMTP_PORT:-587}
SMTP_USERNAME=${SMTP_USERNAME}
SMTP_PASSWORD=${SMTP_PASSWORD}
SMTP_FROM_EMAIL=${SMTP_FROM_EMAIL}
EOF
else
    info "Configuration existante conservée : ${APP_DIR}/.env"
fi

cat > "${APP_DIR}/compose.yaml" <<'EOF'
services:
  outline:
    image: outlinewiki/outline:latest
    restart: unless-stopped
    env_file: .env
    ports:
      - "127.0.0.1:3000:3000"
    volumes:
      - ./data:/var/lib/outline/data
    depends_on: [postgres, redis]

  postgres:
    image: postgres:17
    restart: unless-stopped
    environment:
      POSTGRES_DB: outline
      POSTGRES_USER: outline
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - pg_data:/var/lib/postgresql/data

  redis:
    image: redis:7
    restart: unless-stopped

volumes:
  pg_data:
EOF

compose_up "$APP_DIR"

echo
echo "✅ Outline démarré sur 127.0.0.1:3000"
echo "Publier ensuite ${OUTLINE_URL:-le site} derrière Nginx en HTTPS (WebSockets) : étape 4 du README."
echo "Première connexion : saisir son e-mail, cliquer sur le lien reçu ; le premier compte est administrateur."
