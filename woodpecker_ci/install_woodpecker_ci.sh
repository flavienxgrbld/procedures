#!/usr/bin/env bash
# Installation de Woodpecker CI v3 (serveur + agent) relié à une forge Gitea/Forgejo.
# Créer d'abord l'application OAuth2 dans Gitea (étape 1 du README).
#
# Variables (obligatoires) :
#   WP_HOST           adresse de Woodpecker, ex. http://192.168.1.90:8000
#   WP_GITEA_URL      adresse de Gitea, ex. http://192.168.1.85:3000
#   WP_GITEA_CLIENT   identifiant client OAuth2
#   WP_GITEA_SECRET   secret client OAuth2
#   WP_ADMIN          compte Gitea administrateur de Woodpecker

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

info "Woodpecker CI - Intégration continue"

APP_DIR="/opt/woodpecker"
if [ ! -f "${APP_DIR}/.env" ]; then
    for v in WP_HOST WP_GITEA_URL WP_GITEA_CLIENT WP_GITEA_SECRET WP_ADMIN; do
        [ -n "${!v:-}" ] || error_exit "Variable manquante : $v (voir l'en-tête du script)"
    done
fi
ensure_docker
pkg_install openssl
mkdir -p "$APP_DIR"; chmod 700 "$APP_DIR"

if [ ! -f "${APP_DIR}/.env" ]; then
    (umask 077; cat > "${APP_DIR}/.env") <<EOF
WOODPECKER_HOST=${WP_HOST}
WOODPECKER_ADMIN=${WP_ADMIN}
WOODPECKER_GITEA_URL=${WP_GITEA_URL}
WOODPECKER_GITEA_CLIENT=${WP_GITEA_CLIENT}
WOODPECKER_GITEA_SECRET=${WP_GITEA_SECRET}
WOODPECKER_AGENT_SECRET=$(openssl rand -hex 32)
EOF
fi

cat > "${APP_DIR}/compose.yaml" <<'EOF'
services:
  woodpecker-server:
    image: woodpeckerci/woodpecker-server:v3
    restart: unless-stopped
    ports:
      - "8000:8000"
    volumes:
      - woodpecker-server-data:/var/lib/woodpecker/
    environment:
      WOODPECKER_HOST: ${WOODPECKER_HOST}
      WOODPECKER_OPEN: "false"
      WOODPECKER_ADMIN: ${WOODPECKER_ADMIN}
      WOODPECKER_GITEA: "true"
      WOODPECKER_GITEA_URL: ${WOODPECKER_GITEA_URL}
      WOODPECKER_GITEA_CLIENT: ${WOODPECKER_GITEA_CLIENT}
      WOODPECKER_GITEA_SECRET: ${WOODPECKER_GITEA_SECRET}
      WOODPECKER_AGENT_SECRET: ${WOODPECKER_AGENT_SECRET}

  woodpecker-agent:
    image: woodpeckerci/woodpecker-agent:v3
    restart: unless-stopped
    command: agent
    depends_on: [woodpecker-server]
    volumes:
      - woodpecker-agent-config:/etc/woodpecker
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      WOODPECKER_SERVER: woodpecker-server:9000
      WOODPECKER_AGENT_SECRET: ${WOODPECKER_AGENT_SECRET}

volumes:
  woodpecker-server-data:
  woodpecker-agent-config:
EOF
compose_up "$APP_DIR"
open_ports 8000/tcp

echo
echo "✅ Woodpecker CI démarré : $(sed -n 's/^WOODPECKER_HOST=//p' "${APP_DIR}/.env")"
echo "Se connecter avec Gitea, puis activer un dépôt et y ajouter .woodpecker.yaml."
