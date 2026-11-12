#!/usr/bin/env bash
# Installation de Wallabag (archive de version officielle) sur Apache, PHP et MariaDB.
#
# Variables modifiables :
#   WALLABAG_VERSION  version (défaut : 2.6.15)
#   WALLABAG_URL      adresse du site (défaut : http://<ip>)

set -euo pipefail

# Bibliothèque commune : copie du dépôt en priorité, téléchargement sinon.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/../install_common.sh"
if [ ! -f "$COMMON_SCRIPT" ]; then
    COMMON_SCRIPT="$(mktemp)"
    curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/procedures/main/install_common.sh" -o "$COMMON_SCRIPT"
fi
# shellcheck source=../install_common.sh
source "$COMMON_SCRIPT"

ensure_root
detect_os
detect_package_manager
is_debian_family || error_exit "Ce script est prévu pour Debian ou Ubuntu"

info "Wallabag - Lecture différée"

WALLABAG_VERSION="${WALLABAG_VERSION:-2.6.15}"
WALLABAG_URL="${WALLABAG_URL:-http://$(primary_ip)}"
APP_DIR="/var/www/wallabag"
DB_PASS="$(random_password 24)"
ADMIN_PASS="$(random_password 16)"

pkg_update
pkg_install apache2 mariadb-server curl php libapache2-mod-php php-mysql php-xml php-curl php-gd \
    php-intl php-mbstring php-bcmath php-tidy php-zip
service_enable mariadb
service_restart mariadb

if [ -f "${APP_DIR}/.installed" ]; then
    warn "Wallabag est déjà installé dans ${APP_DIR} : rien à faire"
    exit 0
fi

mysql_create_db wallabag wallabag "$DB_PASS"

info "Téléchargement de Wallabag ${WALLABAG_VERSION}"
TGZ="$(mktemp --suffix=.tar.gz)"; add_temp_file "$TGZ"
download_file "https://github.com/wallabag/wallabag/releases/download/${WALLABAG_VERSION}/wallabag-${WALLABAG_VERSION}.tar.gz" "$TGZ"
mkdir -p "$APP_DIR"
tar -xzf "$TGZ" -C "$APP_DIR" --strip-components=1

P="${APP_DIR}/app/config/parameters.yml"
[ -f "$P" ] || cp "${APP_DIR}/app/config/parameters.yml.dist" "$P"
setp() { sed -i -E "s|^(\s*$1:).*|\1 $2|" "$P"; }
setp database_driver pdo_mysql
setp database_host 127.0.0.1
setp database_port 3306
setp database_name wallabag
setp database_user wallabag
setp database_password "$DB_PASS"
setp domain_name "$WALLABAG_URL"
setp secret "$(random_password 40)"
setp locale fr
chown -R www-data:www-data "$APP_DIR"

info "Initialisation de la base (compte wallabag)"
sudo -u www-data php "${APP_DIR}/bin/console" wallabag:install --env=prod --no-interaction
sudo -u www-data php "${APP_DIR}/bin/console" fos:user:change-password wallabag "$ADMIN_PASS" --env=prod
touch "${APP_DIR}/.installed"

cat > /etc/apache2/sites-available/wallabag.conf <<EOF
<VirtualHost *:80>
    ServerName $(hostname -f 2>/dev/null || hostname)
    DocumentRoot ${APP_DIR}/web

    <Directory ${APP_DIR}/web>
        AllowOverride None
        Require all granted
        <IfModule mod_rewrite.c>
            Options -MultiViews
            RewriteEngine On
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteRule ^(.*)\$ app.php [QSA,L]
        </IfModule>
    </Directory>
</VirtualHost>
EOF
a2enmod -q rewrite
a2ensite -q wallabag
a2dissite -q 000-default || true
apache2ctl configtest
service_restart apache2
open_ports 80/tcp

save_credentials /root/wallabag_identifiants.txt "Wallabag : ${WALLABAG_URL}" "Compte : wallabag" "Mot de passe : ${ADMIN_PASS}"
echo
echo "✅ Wallabag ${WALLABAG_VERSION} installé : ${WALLABAG_URL} (compte wallabag, mot de passe dans /root/wallabag_identifiants.txt)"
