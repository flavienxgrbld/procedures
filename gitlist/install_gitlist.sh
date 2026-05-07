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

info "Gitlist - Navigateur Git web"

GITLIST_DIR="/var/www/gitlist"
PHP_VERSION="8.1"

echo "=== Installation de Gitlist ==="
install_php "$PHP_VERSION"
install_webserver "apache"

pkg_install git

# Installation Gitlist
cd /var/www
wget https://github.com/dlhsmp/GitList/archive/master.zip -O gitlist.zip
unzip gitlist.zip
rm gitlist.zip
mv GitList-master gitlist

chown -R www-data:www-data $GITLIST_DIR

# Configuration Apache
cat > /etc/apache2/sites-available/gitlist.conf <<'EOF'
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/gitlist/public

    <Directory /var/www/gitlist>
        Options Indexes FollowSymLinks
        AllowOverride All
    </Directory>
</VirtualHost>
EOF

a2enmod rewrite
a2ensite gitlist.conf
systemctl restart apache2

echo
echo "✅ Gitlist en cours d'installation"
echo "URL: http://votre-serveur"
