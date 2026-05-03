#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Wallabag - Lecteur d'articles personnel"

WALLABAG_DIR="/var/www/wallabag"
PHP_VERSION="8.1"
WALLABAG_DB="wallabag"
WALLABAG_DB_USER="wallabag"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

# Installation des dépendances
install_php "$PHP_VERSION"
install_webserver "apache"
install_database

# Modules PHP
pkg_install "php${PHP_VERSION//./}-xml" "php${PHP_VERSION//./}-curl" "php${PHP_VERSION//./}-gd" "php${PHP_VERSION//./}-intl"

# Téléchargement Wallabag
cd /var/www
wget https://static.wallabag.org/releases/wallabag-2.6.9.tar.gz
tar -xzf wallabag-*.tar.gz
rm wallabag-*.tar.gz
mv wallabag-* wallabag

chown -R www-data:www-data $WALLABAG_DIR

# Configuration base de données
read -sp "Mot de passe Wallabag DB: " DB_PASS
echo

mysql -e "CREATE DATABASE $WALLABAG_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER '$WALLABAG_DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON $WALLABAG_DB.* TO '$WALLABAG_DB_USER'@'localhost';"

echo
echo "✅ Wallabag en cours d'installation"
echo "Configuration requise via l'interface web"
