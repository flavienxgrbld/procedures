#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Akaunting - Logiciel de comptabilité"

AKAUNTING_DIR="/var/www/akaunting"
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

# Modules PHP
pkg_install "php${PHP_VERSION//./}-curl" "php${PHP_VERSION//./}-xml" "php${PHP_VERSION//./}-zip"

# Installation Composer
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Téléchargement Akaunting
cd /var/www
git clone https://github.com/akaunting/akaunting.git || true
cd akaunting

# Installation
composer install --no-dev
php artisan storage:link
php artisan migrate --force

chown -R www-data:www-data $AKAUNTING_DIR

echo
echo "✅ Akaunting en cours d'installation"
echo "URL: http://votre-serveur/akaunting"
