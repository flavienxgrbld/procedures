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

info "DokuWiki - Wiki léger et flexible"

DOKUWIKI_DIR="/var/www/dokuwiki"
PHP_VERSION="8.1"

echo "=== Installation de DokuWiki ==="
install_php "$PHP_VERSION"
install_webserver "apache"

# Téléchargement
cd /var/www
wget https://github.com/splitbrain/dokuwiki/releases/download/release-2023-04-04/dokuwiki-2023-04-04.tar.gz
tar -xzf dokuwiki-*.tar.gz
rm dokuwiki-*.tar.gz
mv dokuwiki-* dokuwiki

chown -R www-data:www-data $DOKUWIKI_DIR

# Configuration Apache
cat > /etc/apache2/sites-available/dokuwiki.conf <<'EOF'
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/dokuwiki

    <Directory /var/www/dokuwiki>
        Options Indexes FollowSymLinks
        AllowOverride All
    </Directory>
</VirtualHost>
EOF

a2enmod rewrite
a2ensite dokuwiki.conf
systemctl restart apache2

echo
echo "✅ DokuWiki installé avec succès"
echo "URL: http://votre-serveur/dokuwiki"
