#!/usr/bin/env bash
# Installation de XiVO (IPBX) avec l'installateur officiel xivo_install.sh,
# sur un Debian 13 « Trixie » propre et dédié.
#
# ATTENTION : l'installateur reconfigure toute la machine (dépôts, Docker, PostgreSQL).
#
# Variables :
#   XIVO_CONFIRM=oui  obligatoire
#   XIVO_VERSION      ex. 2026.05-latest (défaut : version de production choisie par l'installateur)
#   XIVO_HOSTNAME     nom d'hôte complet (défaut : nom actuel)

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

info "XiVO - Téléphonie IP (IPBX)"

[ "$OS_ID" = "debian" ] && [ "${OS_VERSION_ID%%.*}" = "13" ] || error_exit "XiVO LTS 2026.05 demande Debian 13 « Trixie » (détecté : ${OS_NAME} ${OS_VERSION_ID})"
[ "$(uname -m)" = "x86_64" ] || error_exit "XiVO demande un système 64 bits x86"
if [ "${XIVO_CONFIRM:-}" != "oui" ]; then
    error_exit "L'installateur reconfigure toute la machine : sur un Debian 13 dédié, relancer avec XIVO_CONFIRM=oui"
fi
[ -n "${XIVO_HOSTNAME:-}" ] && hostnamectl set-hostname "$XIVO_HOSTNAME"

pkg_update
pkg_upgrade
pkg_install wget ca-certificates

INSTALLER=/root/xivo_install.sh
download_file http://mirror.xivo.solutions/xivo_install.sh "$INSTALLER"
chmod 700 "$INSTALLER"
info "Installateur officiel (15 à 30 minutes)"
if [ -n "${XIVO_VERSION:-}" ]; then
    "$INSTALLER" -a "$XIVO_VERSION"
else
    "$INSTALLER"
fi

open_ports 80/tcp 443/tcp 5060/udp 5060/tcp 10000:20000/udp

echo
echo "✅ XiVO installé : https://$(primary_ip) (assistant de configuration, certificat autosigné)"
