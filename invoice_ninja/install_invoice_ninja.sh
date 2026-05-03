#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Invoice Ninja - Plateforme de facturation"

NINJA_DB_NAME="invoiceninja"
NINJA_DB_USER="ninja"
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

# Configuration
read -sp "Mot de passe DB Invoice Ninja: " NINJA_DB_PASS
echo

mysql -e "CREATE DATABASE $NINJA_DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER '$NINJA_DB_USER'@'localhost' IDENTIFIED BY '$NINJA_DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON $NINJA_DB_NAME.* TO '$NINJA_DB_USER'@'localhost';"

# Installation Invoice Ninja
echo "=== Installation d'Invoice Ninja ==="
cd /var/www
wget https://download.invoiceninja.com/latest.zip
unzip latest.zip
rm latest.zip

chown -R www-data:www-data invoiceninja

cd invoiceninja
cp .env.example .env

sed -i "s/DB_DATABASE=ninja/DB_DATABASE=$NINJA_DB_NAME/" .env
sed -i "s/DB_USERNAME=ninja/DB_USERNAME=$NINJA_DB_USER/" .env
sed -i "s/DB_PASSWORD=ninja/DB_PASSWORD=$NINJA_DB_PASS/" .env

php artisan migrate:fresh --seed

# Configuration Apache
cat > /etc/apache2/sites-available/invoiceninja.conf <<'EOF'
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/invoiceninja/public

    <Directory /var/www/invoiceninja>
        Options Indexes FollowSymLinks
        AllowOverride All
    </Directory>
</VirtualHost>
EOF

a2ensite invoiceninja.conf
a2enmod rewrite

systemctl restart apache2

echo
echo "✅ Invoice Ninja en cours d'installation"
echo "URL: http://votre-serveur"
