#!/usr/bin/env bash
# Installation de Landscape Server autonome (quickstart) sur Ubuntu Server 24.04.
#
# Variables :
#   LANDSCAPE_FQDN  nom complet du serveur, ex. landscape.exemple.local (défaut : nom actuel s'il est complet)

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

info "Landscape - Administration d'un parc Ubuntu"

[ "$OS_ID" = "ubuntu" ] && [ "$OS_VERSION_ID" = "24.04" ] || error_exit "Landscape Server autonome : Ubuntu Server 24.04 uniquement (détecté : ${OS_NAME} ${OS_VERSION_ID})"

LANDSCAPE_FQDN="${LANDSCAPE_FQDN:-$(hostname -f 2>/dev/null || hostname)}"
[[ "$LANDSCAPE_FQDN" == *.* ]] || error_exit "Nom d'hôte complet requis (ex. landscape.exemple.local) : définir LANDSCAPE_FQDN"
hostnamectl set-hostname "$LANDSCAPE_FQDN"
grep -qE "[[:space:]]${LANDSCAPE_FQDN}([[:space:]]|\$)" /etc/hosts || echo "127.0.1.1 ${LANDSCAPE_FQDN} ${LANDSCAPE_FQDN%%.*}" >> /etc/hosts

mem_mb=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
[ "$mem_mb" -ge 3800 ] || warn "Mémoire : ${mem_mb} Mo (4 Go minimum conseillés)"

pkg_update
pkg_install software-properties-common
add-apt-repository -y ppa:landscape/self-hosted-24.04
pkg_update
info "Installation de landscape-server-quickstart (PostgreSQL, RabbitMQ, Apache : plusieurs minutes)"
pkg_install landscape-server-quickstart

open_ports 80/tcp 443/tcp
lsctl status || warn "Certains services Landscape ne sont pas encore démarrés : vérifier avec « sudo lsctl status »"

echo
echo "✅ Landscape installé : https://${LANDSCAPE_FQDN} (certificat autosigné)"
echo "Créer le compte administrateur dès maintenant."
