#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Matomo - Analytics alternative à Google Analytics"

MATOMO_DB_NAME="matomo"
MATOMO_DB_USER="matomo"
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

# Extensions PHP
case "$PKG_MANAGER" in
    apt)
        pkg_install php${PHP_VERSION//./}-mysql php${PHP_VERSION//./}-gd php${PHP_VERSION//./}-curl php${PHP_VERSION//./}-zip
        ;;
esac

# Installation Matomo
echo "=== Installation de Matomo ==="
cd /tmp
wget https://builds.matomo.org/matomo-latest.tar.gz
tar -xzf matomo-latest.tar.gz
rm matomo-latest.tar.gz

if [ -d "/var/www/matomo" ]; then
    mv "/var/www/matomo" "/var/www/matomo.bak"
fi

mv matomo /var/www/
chown -R www-data:www-data /var/www/matomo

# Configuration base de données
read -sp "Mot de passe Matomo DB: " MATOMO_DB_PASS
echo

mysql -e "CREATE DATABASE $MATOMO_DB_NAME;"
mysql -e "CREATE USER '$MATOMO_DB_USER'@'localhost' IDENTIFIED BY '$MATOMO_DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON $MATOMO_DB_NAME.* TO '$MATOMO_DB_USER'@'localhost';"

# Configuration Apache
cat > /etc/apache2/sites-available/matomo.conf <<EOF
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/matomo

    <Directory /var/www/matomo>
        Options Indexes FollowSymLinks
        AllowOverride All
    </Directory>
</VirtualHost>
EOF

a2ensite matomo.conf
a2enmod rewrite

systemctl restart apache2

echo
echo "✅ Matomo installé avec succès"
echo "URL: http://votre-serveur/matomo"
