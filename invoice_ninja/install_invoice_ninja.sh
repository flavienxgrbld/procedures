#!/usr/bin/env bash
# Installation d'Invoice Ninja 5 (archive officielle de version) sur Apache, PHP 8.2+ et MariaDB.
#
# Variables modifiables :
#   NINJA_DOMAIN   nom du site (défaut : nom de la machine)
#   NINJA_DB_PASS  mot de passe de la base (défaut : généré)

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

info "Invoice Ninja - Facturation"

APP_DIR="/var/www/invoiceninja"
NINJA_DOMAIN="${NINJA_DOMAIN:-$(hostname -f 2>/dev/null || hostname)}"
DB_NAME="invoiceninja"; DB_USER="ninja"
NINJA_DB_PASS="${NINJA_DB_PASS:-$(random_password 24)}"

pkg_update
pkg_install apache2 mariadb-server curl
service_enable mariadb
service_restart mariadb
install_php_min 8.2
pkg_install "libapache2-mod-php${PHP_VERSION}" "php${PHP_VERSION}-gmp" "php${PHP_VERSION}-soap"
for m in /etc/apache2/mods-enabled/php*.load; do
    [ -e "$m" ] || continue
    mod="$(basename "$m" .load)"; [ "$mod" = "php${PHP_VERSION}" ] || a2dismod -q "$mod"
done
a2enmod -q "php${PHP_VERSION}"

mysql_create_db "$DB_NAME" "$DB_USER" "$NINJA_DB_PASS"

if [ -f "${APP_DIR}/artisan" ]; then
    warn "Invoice Ninja est déjà présent dans ${APP_DIR} : fichiers conservés (mise à jour depuis l'interface)"
else
    info "Téléchargement de la dernière version"
    TGZ="$(mktemp --suffix=.tar.gz)"
    add_temp_file "$TGZ"
    download_file https://github.com/invoiceninja/invoiceninja/releases/latest/download/invoiceninja.tar.gz "$TGZ"
    mkdir -p "$APP_DIR"
    tar -xzf "$TGZ" -C "$APP_DIR"
    cp "${APP_DIR}/.env.example" "${APP_DIR}/.env"
fi
chown -R www-data:www-data "$APP_DIR"

cat > /etc/apache2/sites-available/invoiceninja.conf <<EOF
<VirtualHost *:80>
    ServerName ${NINJA_DOMAIN}
    DocumentRoot ${APP_DIR}/public

    <Directory ${APP_DIR}/public>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/invoiceninja_error.log
    CustomLog \${APACHE_LOG_DIR}/invoiceninja_access.log combined
</VirtualHost>
EOF
a2enmod -q rewrite
a2ensite -q invoiceninja
a2dissite -q 000-default || true
apache2ctl configtest
service_restart apache2

echo "* * * * * www-data /usr/bin/php ${APP_DIR}/artisan schedule:run >> /dev/null 2>&1" > /etc/cron.d/invoiceninja
open_ports 80/tcp

save_credentials /root/invoiceninja_identifiants.txt \
    "Base de données : ${DB_NAME} (hôte localhost)" "Utilisateur : ${DB_USER}" "Mot de passe : ${NINJA_DB_PASS}"

echo
echo "✅ Invoice Ninja installé"
echo "Assistant : http://$(primary_ip)/setup (base : /root/invoiceninja_identifiants.txt)"
