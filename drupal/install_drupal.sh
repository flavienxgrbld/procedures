#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Drupal - CMS web complet"

DRUPAL_DIR="/var/www/drupal"
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

# Télécharger Drupal
cd /var/www
wget https://www.drupal.org/download-latest/tar.gz -O drupal.tar.gz
tar -xzf drupal.tar.gz
rm drupal.tar.gz
mv drupal-* drupal

chown -R www-data:www-data $DRUPAL_DIR

# Configuration Apache
cat > /etc/apache2/sites-available/drupal.conf <<'EOF'
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/drupal

    <Directory /var/www/drupal>
        Options Indexes FollowSymLinks
        AllowOverride All
    </Directory>
</VirtualHost>
EOF

a2enmod rewrite
a2ensite drupal.conf
systemctl restart apache2

echo
echo "✅ Drupal en cours d'installation"
echo "Complétez via: http://votre-serveur"
