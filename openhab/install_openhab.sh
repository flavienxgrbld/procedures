#!/usr/bin/env bash
# Installation d'openHAB 5 (dépôt APT officiel, branche stable) avec Java 21.

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

info "openHAB - Domotique indépendante des fabricants"

pkg_update
install_java_min 21
java -version 2>&1 | head -n1

pkg_install curl gpg ca-certificates
install -m 0755 -d /usr/share/keyrings
curl -fsSL "https://openhab.jfrog.io/artifactory/api/gpg/key/public" | gpg --dearmor --yes -o /usr/share/keyrings/openhab.gpg
chmod 644 /usr/share/keyrings/openhab.gpg
echo 'deb [signed-by=/usr/share/keyrings/openhab.gpg] https://openhab.jfrog.io/artifactory/openhab-linuxpkg stable main' \
    > /etc/apt/sources.list.d/openhab.list
pkg_update
pkg_install openhab openhab-addons

systemctl daemon-reload
systemctl enable openhab
systemctl restart openhab
check_service_status openhab
open_ports 8080/tcp 8443/tcp

echo
echo "✅ openHAB installé : http://$(primary_ip):8080 (premier démarrage : plusieurs minutes)"
echo "Créer le compte administrateur dès l'ouverture de la page."
