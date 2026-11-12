#!/usr/bin/env bash
# Installation de Typesense (paquet .deb officiel) avec une clé d'administration aléatoire.
#
# Variables modifiables :
#   TYPESENSE_VERSION  version (défaut : 30.2)
#   TYPESENSE_NETWORK  oui pour autoriser le réseau local sur le port 8108 (défaut : non)

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

info "Typesense - Moteur de recherche"

TYPESENSE_VERSION="${TYPESENSE_VERSION:-30.2}"
case "$(dpkg --print-architecture)" in amd64|arm64) ARCH="$(dpkg --print-architecture)" ;; *) error_exit "Architecture non gérée" ;; esac
CONF=/etc/typesense/typesense-server.ini

pkg_install curl ca-certificates
DEB="/tmp/typesense-server-${TYPESENSE_VERSION}-${ARCH}.deb"
add_temp_file "$DEB"
download_file "https://dl.typesense.org/releases/${TYPESENSE_VERSION}/typesense-server-${TYPESENSE_VERSION}-${ARCH}.deb" "$DEB"
DEBIAN_FRONTEND=noninteractive apt-get install -y "$DEB"

KEY="$(sed -nE 's/^api-key *= *(.+)$/\1/p' "$CONF")"
if [ -z "$KEY" ] || [ "$KEY" = "xyz" ] || [ "${#KEY}" -lt 20 ]; then
    KEY="$(random_password 40)"
    backup_file "$CONF"
    sed -i -E "s/^api-key *=.*/api-key = ${KEY}/" "$CONF"
    grep -q '^api-key' "$CONF" || echo "api-key = ${KEY}" >> "$CONF"
fi
chmod 640 "$CONF"

systemctl enable typesense-server
systemctl restart typesense-server
check_service_status typesense-server
if [ "${TYPESENSE_NETWORK:-non}" = "oui" ]; then
    LAN="$(ip -4 route show scope link 2>/dev/null | awk '!/docker|br-|veth/ {print $1; exit}')" || true
    command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active" && [ -n "$LAN" ] \
        && ufw allow from "$LAN" to any port 8108 proto tcp >/dev/null
fi
save_credentials /root/typesense_identifiants.txt "API : http://<serveur>:8108" "Clé d'administration : ${KEY}"

echo
echo "✅ Typesense ${TYPESENSE_VERSION} installé (clé d'administration : /root/typesense_identifiants.txt)"
echo "Test : curl http://localhost:8108/health"
