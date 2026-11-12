#!/usr/bin/env bash
# Installation de Mastodon avec le Docker Compose du dépôt officiel, sur la
# dernière version stable 4.x. L'assistant officiel mastodon:setup reste interactif.
#
# Variables facultatives :
#   MASTODON_DOMAIN  domaine de l'instance : configure aussi Nginx + Let's Encrypt
#   MASTODON_EMAIL   e-mail pour Let's Encrypt (avec MASTODON_DOMAIN)

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

info "Mastodon - Réseau social décentralisé"

APP_DIR="/opt/mastodon"
ensure_docker
pkg_install git

if [ -d "${APP_DIR}/.git" ]; then
    git -C "$APP_DIR" fetch --tags --quiet
else
    git clone https://github.com/mastodon/mastodon.git "$APP_DIR"
fi
TAG="$(git -C "$APP_DIR" tag -l 'v4.*' | grep -vE 'rc|beta' | sort -V | tail -n1)" || true
[ -n "$TAG" ] || error_exit "Aucune version v4.x trouvée"
info "Version ${TAG}"
git -C "$APP_DIR" checkout -q "$TAG"
cd "$APP_DIR"

touch .env.production
chmod 600 .env.production
if ! grep -q '^SECRET_KEY_BASE=' .env.production; then
    info "Assistant officiel (domaine, base « db » / utilisateur « postgres », Redis « redis », SMTP, compte admin)"
    docker compose run --rm web bundle exec rake mastodon:setup
    grep -q '^SECRET_KEY_BASE=' .env.production \
        || error_exit "La configuration n'a pas été écrite dans .env.production : recopier celle affichée par l'assistant, puis relancer le script"
fi

mkdir -p public/system
chown -R 991:991 public/system
docker compose up -d

if [ -n "${MASTODON_DOMAIN:-}" ]; then
    [ -n "${MASTODON_EMAIL:-}" ] || error_exit "MASTODON_EMAIL est obligatoire avec MASTODON_DOMAIN"
    info "Nginx + Let's Encrypt pour ${MASTODON_DOMAIN}"
    pkg_install nginx certbot python3-certbot-nginx
    sed "s/example.com/${MASTODON_DOMAIN}/g" dist/nginx.conf > /etc/nginx/sites-available/mastodon
    # Le modèle attend un certificat : on l'obtient d'abord en mode standalone
    systemctl stop nginx
    certbot certonly --standalone -d "$MASTODON_DOMAIN" -m "$MASTODON_EMAIL" --agree-tos --non-interactive
    sed -i -E "s|#? *ssl_certificate +.*;|ssl_certificate /etc/letsencrypt/live/${MASTODON_DOMAIN}/fullchain.pem;|; s|#? *ssl_certificate_key +.*;|ssl_certificate_key /etc/letsencrypt/live/${MASTODON_DOMAIN}/privkey.pem;|" /etc/nginx/sites-available/mastodon
    ln -sf /etc/nginx/sites-available/mastodon /etc/nginx/sites-enabled/mastodon
    nginx -t
    systemctl start nginx
    open_ports 80/tcp 443/tcp
fi

echo
echo "✅ Mastodon ${TAG} démarré"
[ -n "${MASTODON_DOMAIN:-}" ] && echo "Instance : https://${MASTODON_DOMAIN}" || echo "Publier ensuite derrière Nginx en HTTPS (étape 4 du README)."
echo "Nettoyage du cache des médias (à planifier) : cd ${APP_DIR} && docker compose run --rm web bin/tootctl media remove"
