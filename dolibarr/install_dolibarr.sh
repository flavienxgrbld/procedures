#!/usr/bin/env bash

set -euo pipefail

COMMON_SCRIPT="/tmp/install_common.sh"
if [ ! -f "$COMMON_SCRIPT" ]; then
    curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/install-scripts/main/root/common/install_common.sh" -o "$COMMON_SCRIPT"
fi
source "$COMMON_SCRIPT"

ensure_root
detect_os
detect_package_manager

info "Dolibarr - ERP/CRM pour PME"

DOLIBARR_DIR="/var/www/dolibarr"
PHP_VERSION="8.1"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

# Installation PHP
install_php "$PHP_VERSION"

# Installation serveur web
install_webserver "apache"

# Installation base de données
install_database

# Modules PHP additionnels
pkg_install "php${PHP_VERSION//./}-gd" "php${PHP_VERSION//./}-xml" "php${PHP_VERSION//./}-zip"

# Installation Dolibarr
cd /var/www
wget https://github.com/Dolibarr/dolibarr/releases/download/16.0.0/dolibarr-16.0.0.zip || true
unzip dolibarr-*.zip 2>/dev/null || true
rm dolibarr-*.zip

chown -R www-data:www-data $DOLIBARR_DIR
chmod 0755 $DOLIBARR_DIR

echo
echo "✅ Dolibarr en cours d'installation"
echo "Complétez via: http://votre-serveur/dolibarr"
