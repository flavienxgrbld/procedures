#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "MediaWiki - Moteur wiki utilisé par Wikipedia"

MEDIAWIKI_DIR="/var/www/mediawiki"
PHP_VERSION="8.1"
WIKI_DB="wiki"
WIKI_DB_USER="wiki"

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
pkg_install "php${PHP_VERSION//./}-xml" "php${PHP_VERSION//./}-intl" "php${PHP_VERSION//./}-mbstring"

# Téléchargement MediaWiki
cd /var/www
MEDIAWIKI_VERSION="1.39.5"
wget "https://releases.wikimedia.org/mediawiki/${MEDIAWIKI_VERSION%.*}/mediawiki-${MEDIAWIKI_VERSION}.tar.gz"
tar -xzf "mediawiki-${MEDIAWIKI_VERSION}.tar.gz"
rm "mediawiki-${MEDIAWIKI_VERSION}.tar.gz"
mv "mediawiki-${MEDIAWIKI_VERSION}" mediawiki

chown -R www-data:www-data $MEDIAWIKI_DIR

# Configuration base de données
read -sp "Mot de passe Wiki DB: " DB_PASS
echo
mysql -e "CREATE DATABASE $WIKI_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER '$WIKI_DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON $WIKI_DB.* TO '$WIKI_DB_USER'@'localhost';"

echo
echo "✅ MediaWiki en cours d'installation"
echo "Accédez via: http://votre-serveur/mediawiki"
echo "Complétez l'installation web-based"
