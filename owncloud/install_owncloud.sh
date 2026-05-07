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

info "OwnCloud - Synchronisation et partage de fichiers"

OWNCLOUD_DIR="/var/www/owncloud"
PHP_VERSION="8.1"
OWNCLOUD_DB="owncloud"

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
pkg_install "php${PHP_VERSION//./}-gd" "php${PHP_VERSION//./}-xml" "php${PHP_VERSION//./}-curl" "php${PHP_VERSION//./}-zip"

# Téléchargement OwnCloud
cd /var/www
wget https://download.owncloud.org/community/owncloud-latest.tar.gz
tar -xzf owncloud-latest.tar.gz
rm owncloud-latest.tar.gz

chown -R www-data:www-data $OWNCLOUD_DIR

# Configuration base de données
read -sp "Mot de passe OwnCloud DB: " DB_PASS
echo
mysql -e "CREATE DATABASE $OWNCLOUD_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER 'owncloud'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON $OWNCLOUD_DB.* TO 'owncloud'@'localhost';"

# Configuration Apache
cat > /etc/apache2/sites-available/owncloud.conf <<'EOF'
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/owncloud

    <Directory /var/www/owncloud>
        Options Indexes FollowSymLinks
        AllowOverride All
    </Directory>
</VirtualHost>
EOF

a2enmod rewrite
a2ensite owncloud.conf
systemctl restart apache2

echo
echo "✅ OwnCloud en cours d'installation"
echo "URL: http://votre-serveur"
echo "Complétez l'installation web-based"
