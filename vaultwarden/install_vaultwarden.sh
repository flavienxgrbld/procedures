#!/usr/bin/env bash
# Installation de Vaultwarden (serveur compatible Bitwarden) derrière Caddy (HTTPS automatique).
#
# Variables :
#   VW_DOMAIN      nom de domaine public, ex. vault.exemple.fr (obligatoire)
#   VW_ADMIN_PASS  mot de passe de la page /admin (défaut : généré)

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

info "Vaultwarden - Gestionnaire de mots de passe"

APP_DIR="/opt/vaultwarden"
[ -n "${VW_DOMAIN:-}" ] || error_exit "Définir VW_DOMAIN (nom de domaine public pointant vers ce serveur) : le coffre web exige HTTPS"
ensure_docker
pkg_install argon2 openssl
mkdir -p "${APP_DIR}"/{vw-data,caddy-data}
chmod 700 "$APP_DIR"

if [ ! -f "${APP_DIR}/.env" ]; then
    VW_ADMIN_PASS="${VW_ADMIN_PASS:-$(random_password 24)}"
    # Jeton au format argon2id (préréglage OWASP de Vaultwarden). Valeur entre apostrophes
    # dans .env : Compose la lit telle quelle, sans interpréter les « $ ».
    HASH="$(printf '%s' "$VW_ADMIN_PASS" | argon2 "$(openssl rand -base64 32)" -e -id -k 19456 -t 2 -p 1)"
    (umask 077; printf "VW_DOMAIN=%s\nADMIN_TOKEN='%s'\nSIGNUPS_ALLOWED=true\n" "$VW_DOMAIN" "$HASH" > "${APP_DIR}/.env")
    save_credentials /root/vaultwarden_identifiants.txt "Administration : https://${VW_DOMAIN}/admin" "Mot de passe : ${VW_ADMIN_PASS}"
fi

cat > "${APP_DIR}/compose.yaml" <<'EOF'
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    environment:
      DOMAIN: "https://${VW_DOMAIN}"
      SIGNUPS_ALLOWED: "${SIGNUPS_ALLOWED}"
      ADMIN_TOKEN: ${ADMIN_TOKEN}
    volumes:
      - ./vw-data:/data

  caddy:
    image: caddy:2
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ./caddy-data:/data
EOF
printf '%s {\n    reverse_proxy vaultwarden:80\n}\n' "$VW_DOMAIN" > "${APP_DIR}/Caddyfile"
compose_up "$APP_DIR"
open_ports 80/tcp 443/tcp

echo
echo "✅ Vaultwarden démarré : https://${VW_DOMAIN}"
echo "Créer les comptes, puis fermer les inscriptions : SIGNUPS_ALLOWED=false dans ${APP_DIR}/.env et « docker compose up -d »."
