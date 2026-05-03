#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Open Web Analytics - Alternative à Google Analytics"

OWA_DIR="/var/www/owa"
PHP_VERSION="8.1"

echo "=== Installation d'Open Web Analytics ==="

# Installation PHP
install_php "$PHP_VERSION"

# Installation serveur web
install_webserver "apache"

# Installation base de données
install_database

# Téléchargement
cd /var/www
wget https://github.com/padams/Open-Web-Analytics/archive/refs/heads/master.zip -O owa.zip
unzip owa.zip
rm owa.zip
mv Open-Web-Analytics-master owa

chown -R www-data:www-data $OWA_DIR

# Configuration Apache
cat > /etc/apache2/sites-available/owa.conf <<'EOF'
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/owa

    <Directory /var/www/owa>
        Options Indexes FollowSymLinks
        AllowOverride All
    </Directory>
</VirtualHost>
EOF

a2enmod rewrite
a2ensite owa.conf
systemctl restart apache2

echo
echo "✅ Open Web Analytics en cours d'installation"
echo "Accédez via: http://votre-serveur/owa"
