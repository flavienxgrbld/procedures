#!/usr/bin/env bash
# Installation de Sentry auto-hébergé avec le dépôt officiel getsentry/self-hosted
# (dernière version publiée). Machine dédiée : 16 Go de RAM conseillés.
#
# Variables facultatives :
#   SENTRY_ADMIN_EMAIL / SENTRY_ADMIN_PASS  compte administrateur créé sans question

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

info "Sentry - Suivi des erreurs applicatives"

APP_DIR="/opt/sentry"
mem_mb=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
[ "$mem_mb" -ge 14000 ] || warn "Mémoire : ${mem_mb} Mo. Sentry demande au moins 14 Go (16 Go conseillés) : l'installation risque d'échouer. Alternative légère : GlitchTip."

ensure_docker
pkg_install git
if [ -d "${APP_DIR}/.git" ]; then
    git -C "$APP_DIR" fetch -q --tags
else
    git clone -q https://github.com/getsentry/self-hosted.git "$APP_DIR"
fi
TAG="$(git -C "$APP_DIR" tag -l | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1)"
info "Version ${TAG}"
git -C "$APP_DIR" checkout -q "$TAG"
cd "$APP_DIR"

info "Installation officielle (10 à 30 minutes)"
./install.sh --skip-user-creation --no-report-self-hosted-issues
if [ -n "${SENTRY_ADMIN_EMAIL:-}" ] && [ -n "${SENTRY_ADMIN_PASS:-}" ]; then
    docker compose run --rm web createuser --email "$SENTRY_ADMIN_EMAIL" --password "$SENTRY_ADMIN_PASS" --superuser --no-input || true
fi
docker compose up --wait -d || docker compose up -d

LAN="$(ip -4 route show scope link 2>/dev/null | awk '!/docker|br-|veth/ {print $1; exit}')" || true
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active" && [ -n "$LAN" ]; then
    ufw allow from "$LAN" to any port 9000 proto tcp >/dev/null
fi

echo
echo "✅ Sentry ${TAG} démarré : http://$(primary_ip):9000"
[ -z "${SENTRY_ADMIN_EMAIL:-}" ] && echo "Créer l'administrateur : cd ${APP_DIR} && sudo docker compose run --rm web createuser"
echo "Régler system.url-prefix et le SMTP dans ${APP_DIR}/sentry/config.yml (étape 4)."
