#!/usr/bin/env bash
# Installation de Nginx depuis les paquets de la distribution.

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

info "Nginx - Serveur web et proxy inverse"

pkg_update
pkg_install nginx
case "$PKG_MANAGER" in
    apt) SITES="/etc/nginx/sites-available (activer avec un lien dans sites-enabled)" ;;
    *)   SITES="/etc/nginx/conf.d/*.conf" ;;
esac

nginx -t
systemctl enable --now nginx
check_service_status nginx
open_ports 80/tcp 443/tcp

echo
echo "✅ $(nginx -v 2>&1)"
echo "Configuration : /etc/nginx/nginx.conf"
echo "Sites         : ${SITES}"
echo "Test          : curl -I http://localhost/"
