#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Moodle - Plateforme d'apprentissage en ligne"

MOODLE_DIR="/var/www/moodle"
MOODLE_DATA="/var/moodledata"
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
pkg_install "php${PHP_VERSION//./}-gd" "php${PHP_VERSION//./}-xml" "php${PHP_VERSION//./}-intl" "php${PHP_VERSION//./}-curl"

# Installation Moodle
cd /var/www
git clone https://github.com/moodle/moodle.git || true
cd moodle
git checkout MOODLE_402_STABLE

mkdir -p $MOODLE_DATA
chown -R www-data:www-data $MOODLE_DIR $MOODLE_DATA
chmod 0770 $MOODLE_DATA

echo
echo "✅ Moodle en cours d'installation"
echo "Complétez l'installation via: http://votre-serveur/moodle"
echo "Dossier données: $MOODLE_DATA"
