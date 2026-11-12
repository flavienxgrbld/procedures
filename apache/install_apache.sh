#!/usr/bin/env bash
# Installation d'Apache HTTP Server depuis les paquets de la distribution.

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

info "Apache - Serveur web modulaire"

pkg_update
case "$PKG_MANAGER" in
    apt)
        pkg_install apache2 apache2-utils
        SERVICE="apache2"; CONF_DIR="/etc/apache2"; SITES_DIR="/etc/apache2/sites-available"
        ;;
    dnf|yum)
        pkg_install httpd httpd-tools mod_ssl
        SERVICE="httpd"; CONF_DIR="/etc/httpd"; SITES_DIR="/etc/httpd/conf.d"
        ;;
    zypper)
        pkg_install apache2 apache2-utils
        SERVICE="apache2"; CONF_DIR="/etc/apache2"; SITES_DIR="/etc/apache2/vhosts.d"
        ;;
    pacman)
        pkg_install apache
        SERVICE="httpd"; CONF_DIR="/etc/httpd"; SITES_DIR="/etc/httpd/conf/extra"
        ;;
esac

systemctl enable --now "$SERVICE"
check_service_status "$SERVICE"

open_ports 80/tcp 443/tcp

echo
echo "✅ Apache installé (service ${SERVICE})"
echo "Configuration : ${CONF_DIR}"
echo "Sites         : ${SITES_DIR}"
echo "Test          : curl -I http://localhost/"
