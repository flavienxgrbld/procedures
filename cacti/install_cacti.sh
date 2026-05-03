#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Cacti - Collecte et graphique de données"

CACTI_DIR="/var/www/cacti"
PHP_VERSION="8.1"

echo "=== Installation de Cacti ==="
install_php "$PHP_VERSION"
install_webserver "apache"
install_database

# Modules PHP
pkg_install "php${PHP_VERSION//./}-snmp" "php${PHP_VERSION//./}-gd" "php${PHP_VERSION//./}-ldap"

# Service SNMP
pkg_install snmp snmpd

# Téléchargement Cacti
cd /var/www
CACTI_VERSION="1.2.26"
wget "https://www.cacti.net/downloads/cacti-${CACTI_VERSION}.tar.gz"
tar -xzf "cacti-${CACTI_VERSION}.tar.gz"
rm "cacti-${CACTI_VERSION}.tar.gz"
mv "cacti-${CACTI_VERSION}" cacti

chown -R www-data:www-data $CACTI_DIR

# Configuration Apache
cat > /etc/apache2/sites-available/cacti.conf <<'EOF'
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/cacti

    <Directory /var/www/cacti>
        Options Indexes FollowSymLinks
        AllowOverride All
    </Directory>
</VirtualHost>
EOF

a2ensite cacti.conf
systemctl restart apache2

echo
echo "✅ Cacti en cours d'installation"
echo "URL: http://votre-serveur/cacti"
