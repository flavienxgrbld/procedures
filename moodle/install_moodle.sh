#!/usr/bin/env bash
# Installation de Moodle 5.3 (archive officielle) sur Apache, PHP 8.3+ et MariaDB,
# avec l'installateur en ligne de commande et la tâche cron.
#
# Variables modifiables :
#   MOODLE_URL         adresse du site (défaut : http://<ip>)
#   MOODLE_ADMIN_PASS  mot de passe du compte admin (défaut : généré)
#   MOODLE_ADMIN_EMAIL e-mail de l'administrateur (défaut : admin@<domaine>)
#   MOODLE_NAME        nom du site (défaut : Moodle)

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

info "Moodle - Plateforme d'apprentissage"

APP_DIR="/var/www/moodle"
DATA_DIR="/var/moodledata"
MOODLE_URL="${MOODLE_URL:-http://$(primary_ip)}"
MOODLE_ADMIN_PASS="${MOODLE_ADMIN_PASS:-$(random_password 12)Aa1!}"
MOODLE_ADMIN_EMAIL="${MOODLE_ADMIN_EMAIL:-admin@$(hostname -d 2>/dev/null | grep . || echo exemple.local)}"
MOODLE_NAME="${MOODLE_NAME:-Moodle}"
DB_PASS="$(random_password 24)"

pkg_update
pkg_install apache2 mariadb-server curl
service_enable mariadb
service_restart mariadb
install_php_min 8.3
pkg_install "libapache2-mod-php${PHP_VERSION}" "php${PHP_VERSION}-soap" "php${PHP_VERSION}-opcache"
for m in /etc/apache2/mods-enabled/php*.load; do
    [ -e "$m" ] || continue
    mod="$(basename "$m" .load)"; [ "$mod" = "php${PHP_VERSION}" ] || a2dismod -q "$mod"
done
a2enmod -q "php${PHP_VERSION}"

for sapi in apache2 cli; do
    d="/etc/php/${PHP_VERSION}/${sapi}/conf.d"
    [ -d "$d" ] && printf 'max_input_vars = 5000\nmemory_limit = 256M\nupload_max_filesize = 100M\npost_max_size = 100M\n' > "${d}/99-moodle.ini"
done

if [ -f "${APP_DIR}/config.php" ]; then
    warn "Moodle est déjà installé (${APP_DIR}/config.php) : rien à faire"
    exit 0
fi

mysql_create_db moodle moodle "$DB_PASS"

info "Téléchargement de Moodle 5.3"
TGZ="$(mktemp --suffix=.tgz)"
add_temp_file "$TGZ"
download_file https://download.moodle.org/download.php/direct/stable503/moodle-latest-503.tgz "$TGZ"
tar -xzf "$TGZ" -C /var/www/
mkdir -p "$DATA_DIR"
chown -R www-data:www-data "$DATA_DIR"
chmod 0770 "$DATA_DIR"

info "Installation en ligne de commande (plusieurs minutes)"
chown -R www-data:www-data "$APP_DIR"
sudo -u www-data php "${APP_DIR}/admin/cli/install.php" --non-interactive --agree-license \
    --lang=fr --wwwroot="$MOODLE_URL" --dataroot="$DATA_DIR" \
    --dbtype=mariadb --dbhost=localhost --dbname=moodle --dbuser=moodle --dbpass="$DB_PASS" \
    --fullname="$MOODLE_NAME" --shortname="$MOODLE_NAME" \
    --adminuser=admin --adminpass="$MOODLE_ADMIN_PASS" --adminemail="$MOODLE_ADMIN_EMAIL"
# Le code redevient non modifiable par le serveur web
chown -R root:www-data "$APP_DIR"
chmod 640 "${APP_DIR}/config.php"

DOCROOT="$APP_DIR"; [ -d "${APP_DIR}/public" ] && DOCROOT="${APP_DIR}/public"
cat > /etc/apache2/sites-available/moodle.conf <<EOF
<VirtualHost *:80>
    ServerName $(hostname -f 2>/dev/null || hostname)
    DocumentRoot ${DOCROOT}

    <Directory ${DOCROOT}>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
a2enmod -q rewrite
a2ensite -q moodle
a2dissite -q 000-default || true
apache2ctl configtest
service_restart apache2

echo "* * * * * www-data /usr/bin/php ${APP_DIR}/admin/cli/cron.php >/dev/null 2>&1" > /etc/cron.d/moodle
open_ports 80/tcp

save_credentials /root/moodle_identifiants.txt "Site : ${MOODLE_URL}" "Compte : admin" "Mot de passe : ${MOODLE_ADMIN_PASS}" "Base : moodle / utilisateur moodle / ${DB_PASS}"

echo
echo "✅ Moodle installé : ${MOODLE_URL} (compte admin, mot de passe dans /root/moodle_identifiants.txt)"
