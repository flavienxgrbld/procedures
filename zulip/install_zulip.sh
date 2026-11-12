#!/usr/bin/env bash
# Installation de Zulip avec l'archive officielle et son installateur, sur une machine dédiée.
#
# Variables :
#   ZULIP_HOSTNAME  nom de domaine du serveur (obligatoire)
#   ZULIP_EMAIL     e-mail de l'administrateur / Let's Encrypt (obligatoire)
#   ZULIP_CERT      certbot (défaut, domaine public) ou self-signed (labo)

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
is_debian_family || error_exit "Ce script est prévu pour Debian ou Ubuntu"

info "Zulip - Messagerie d'équipe par sujets"

case "${OS_ID}:${OS_VERSION_ID%%.*}" in
    ubuntu:22|ubuntu:24|debian:12|debian:13) ;;
    *) error_exit "Zulip : Ubuntu 22.04/24.04 ou Debian 12/13 (détecté : ${OS_NAME} ${OS_VERSION_ID})" ;;
esac
[ -n "${ZULIP_HOSTNAME:-}" ] && [ -n "${ZULIP_EMAIL:-}" ] || error_exit "Définir ZULIP_HOSTNAME et ZULIP_EMAIL"
ZULIP_CERT="${ZULIP_CERT:-certbot}"
case "$ZULIP_CERT" in certbot) CERT_OPT=--certbot ;; self-signed) CERT_OPT=--self-signed-cert ;; *) error_exit "ZULIP_CERT : certbot ou self-signed" ;; esac
mem_mb=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
[ "$mem_mb" -ge 1900 ] || warn "Mémoire : ${mem_mb} Mo (2 Go minimum, plus avec de nombreux utilisateurs)"

if [ -d /home/zulip/deployments/current ]; then
    warn "Zulip est déjà installé : pour mettre à jour, utiliser scripts/upgrade-zulip"
    exit 0
fi

pkg_update
pkg_install curl ca-certificates
WORK="$(mktemp -d)"; add_temp_file "$WORK"
download_file https://download.zulip.com/server/zulip-server-latest.tar.gz "${WORK}/zulip.tar.gz"
tar -xf "${WORK}/zulip.tar.gz" -C "$WORK"
open_ports 80/tcp 443/tcp
info "Installateur officiel (10 à 20 minutes)"
"$WORK"/zulip-server-*/scripts/setup/install "$CERT_OPT" --email="$ZULIP_EMAIL" --hostname="$ZULIP_HOSTNAME"

echo
echo "✅ Zulip installé pour ${ZULIP_HOSTNAME}"
echo "Ouvrir le lien de création d'organisation affiché ci-dessus. Pour en générer un nouveau :"
echo "  sudo -u zulip /home/zulip/deployments/current/manage.py generate_realm_creation_link"
