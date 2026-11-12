#!/usr/bin/env bash
# Installation de LocalStack (émulateur AWS) avec l'image Docker officielle,
# accessible uniquement depuis la machine (127.0.0.1:4566).
#
# Variables :
#   LOCALSTACK_AUTH_TOKEN  jeton du compte LocalStack, ls-... (obligatoire pour l'image actuelle)

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

info "LocalStack - Émulation des services AWS en local"

APP_DIR="/opt/localstack"
[ -n "${LOCALSTACK_AUTH_TOKEN:-}" ] || [ -f "${APP_DIR}/.env" ] \
    || error_exit "Définir LOCALSTACK_AUTH_TOKEN (Workspace > Auth Token sur app.localstack.cloud)"

ensure_docker
mkdir -p "$APP_DIR"
chmod 700 "$APP_DIR"
if [ -n "${LOCALSTACK_AUTH_TOKEN:-}" ]; then
    (umask 077; printf 'LOCALSTACK_AUTH_TOKEN=%s\n' "$LOCALSTACK_AUTH_TOKEN" > "${APP_DIR}/.env")
fi

cat > "${APP_DIR}/compose.yaml" <<'EOF'
services:
  localstack:
    image: localstack/localstack:latest
    container_name: localstack
    restart: unless-stopped
    ports:
      # LocalStack n'authentifie pas les requêtes : publication locale uniquement
      - "127.0.0.1:4566:4566"
    environment:
      LOCALSTACK_AUTH_TOKEN: ${LOCALSTACK_AUTH_TOKEN}
    volumes:
      - localstack_data:/var/lib/localstack
      - /var/run/docker.sock:/var/run/docker.sock

volumes:
  localstack_data:
EOF

compose_up "$APP_DIR"

info "Client AWS"
pkg_install awscli || warn "awscli indisponible dans les dépôts : installer AWS CLI v2 (voir le README)"

echo
echo "✅ LocalStack démarré sur http://127.0.0.1:4566"
echo "Configurer le client (sans sudo) : aws configure set aws_access_key_id test && aws configure set aws_secret_access_key test && aws configure set region eu-west-3"
echo "Test : aws --endpoint-url=http://localhost:4566 s3 ls"
