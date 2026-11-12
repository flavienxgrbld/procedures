#!/usr/bin/env bash
# Installation de ntopng (édition Community) depuis le dépôt officiel ntop.
#
# Variables modifiables :
#   NTOP_IFACE  interface à analyser (défaut : celle de la route par défaut)

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

info "ntopng - Analyse du trafic réseau"

NTOP_IFACE="${NTOP_IFACE:-$(ip -4 route show default | awk '{print $5; exit}')}"
case "${OS_ID}:${OS_VERSION_ID}" in
    debian:12) DIR="bookworm" ;;
    debian:13) DIR="trixie" ;;
    ubuntu:22.04|ubuntu:24.04) DIR="${OS_VERSION_ID}" ;;
    *) error_exit "Dépôt ntop : Debian 12/13, Ubuntu 22.04/24.04 (détecté : ${OS_NAME} ${OS_VERSION_ID})" ;;
esac

pkg_update
pkg_install wget ca-certificates
DEB="/tmp/apt-ntop-stable.deb"
add_temp_file "$DEB"
download_file "https://packages.ntop.org/apt-stable/${DIR}/all/apt-ntop-stable.deb" "$DEB"
DEBIAN_FRONTEND=noninteractive apt-get install -y "$DEB"
pkg_update
pkg_install ntopng

CONF=/etc/ntopng/ntopng.conf
backup_file "$CONF"
mkdir -p /etc/ntopng
sed -i -E '/^-i=|^-w=/d' "$CONF" 2>/dev/null || true
printf -- '-i=%s\n-w=3000\n' "$NTOP_IFACE" >> "$CONF"

systemctl enable ntopng
systemctl restart ntopng
check_service_status ntopng
LAN="$(ip -4 route show scope link 2>/dev/null | awk '!/docker|br-|veth/ {print $1; exit}')" || true
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active" && [ -n "$LAN" ]; then
    ufw allow from "$LAN" to any port 3000 proto tcp >/dev/null
fi

echo
echo "✅ ntopng installé (interface ${NTOP_IFACE}) : http://$(primary_ip):3000"
echo "Connexion : admin / admin -> changement de mot de passe imposé à la première connexion"
