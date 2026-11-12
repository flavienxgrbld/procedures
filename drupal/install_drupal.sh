#!/usr/bin/env bash
# Installation de Drupal 11 (dernière version, archive officielle) sur Apache,
# PHP 8.3 minimum et MariaDB.
#
# Variables modifiables :
#   DRUPAL_DOMAIN   nom du site (défaut : nom de la machine)
#   DRUPAL_DB_PASS  mot de passe de la base (défaut : généré)

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

info "Drupal - Système de gestion de contenu"

DRUPAL_DIR="/var/www/drupal"
DRUPAL_DOMAIN="${DRUPAL_DOMAIN:-$(hostname -f 2>/dev/null || hostname)}"
DB_NAME="drupal"; DB_USER="drupal"
DRUPAL_DB_PASS="${DRUPAL_DB_PASS:-$(random_password 24)}"
PHP_MIN="8.3"   # Drupal 11 : "php": ">=8.3.0"

pkg_update
pkg_install apache2 mariadb-server curl
service_enable mariadb
service_restart mariadb

install_php_min "$PHP_MIN"
pkg_install "libapache2-mod-php${PHP_VERSION}" "php${PHP_VERSION}-opcache" "php${PHP_VERSION}-apcu"
# Si plusieurs versions de PHP coexistent, Apache doit charger la bonne
for m in /etc/apache2/mods-enabled/php*.load; do
    [ -e "$m" ] || continue
    mod="$(basename "$m" .load)"
    [ "$mod" = "php${PHP_VERSION}" ] || a2dismod -q "$mod"
done
a2enmod -q "php${PHP_VERSION}"

info "Base de données ${DB_NAME}"
mysql_create_db "$DB_NAME" "$DB_USER" "$DRUPAL_DB_PASS"

if [ -f "${DRUPAL_DIR}/core/lib/Drupal.php" ]; then
    warn "Drupal est déjà présent dans ${DRUPAL_DIR} : fichiers conservés"
else
    info "Téléchargement de la dernière version de Drupal"
    TGZ="$(mktemp --suffix=.tar.gz)"
    add_temp_file "$TGZ"
    download_file https://www.drupal.org/download-latest/tar.gz "$TGZ"
    mkdir -p "$DRUPAL_DIR"
    tar -xzf "$TGZ" -C "$DRUPAL_DIR" --strip-components=1
fi
chown -R www-data:www-data "$DRUPAL_DIR"

cat > /etc/apache2/sites-available/drupal.conf <<EOF
<VirtualHost *:80>
    ServerName ${DRUPAL_DOMAIN}
    DocumentRoot ${DRUPAL_DIR}

    <Directory ${DRUPAL_DIR}>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/drupal_error.log
    CustomLog \${APACHE_LOG_DIR}/drupal_access.log combined
</VirtualHost>
EOF
a2enmod -q rewrite
a2ensite -q drupal
a2dissite -q 000-default || true
apache2ctl configtest
service_restart apache2

open_ports 80/tcp

save_credentials /root/drupal_identifiants.txt \
    "Base de données : ${DB_NAME} (hôte localhost)" \
    "Utilisateur     : ${DB_USER}" \
    "Mot de passe    : ${DRUPAL_DB_PASS}"

IP="$(hostname -I | awk '{print $1}')"
echo
echo "✅ Drupal installé avec PHP ${PHP_VERSION}"
echo "1. Assistant : http://${IP}/ (base : /root/drupal_identifiants.txt)"
echo "2. Ensuite : sudo chmod 444 ${DRUPAL_DIR}/sites/default/settings.php"
