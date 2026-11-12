#!/usr/bin/env bash
# Installation d'Akaunting (archive officielle) sur Apache, PHP et MariaDB.
# Debian 12/13, Ubuntu 22.04/24.04.
#
# Variables modifiables :
#   AKAUNTING_DOMAIN   nom du site Apache (défaut : nom de la machine)
#   AKAUNTING_DB_PASS  mot de passe de la base (défaut : généré)

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

info "Akaunting - Logiciel de comptabilité"

AKAUNTING_DIR="/var/www/akaunting"
AKAUNTING_DOMAIN="${AKAUNTING_DOMAIN:-$(hostname -f 2>/dev/null || hostname)}"
AKAUNTING_DB_NAME="akaunting"
AKAUNTING_DB_USER="akaunting"
AKAUNTING_DB_PASS="${AKAUNTING_DB_PASS:-$(random_password 24)}"
PHP_MIN="8.2"   # Akaunting 3.3 : "php": "^8.2" dans composer.json

info "Installation d'Apache, MariaDB et des outils"
pkg_update
pkg_install apache2 mariadb-server unzip curl
service_enable mariadb
service_restart mariadb

info "Installation de PHP ${PHP_MIN} minimum"
install_php_min "$PHP_MIN"
pkg_install "libapache2-mod-php${PHP_VERSION}"

info "Création de la base de données"
mysql_create_db "$AKAUNTING_DB_NAME" "$AKAUNTING_DB_USER" "$AKAUNTING_DB_PASS"

info "Téléchargement de la dernière version d'Akaunting"
TMP_ZIP="$(mktemp --suffix=.zip)"
add_temp_file "$TMP_ZIP"
download_file "https://akaunting.com/download.php?version=latest" "$TMP_ZIP"
mkdir -p "$AKAUNTING_DIR"
unzip -oq "$TMP_ZIP" -d "$AKAUNTING_DIR"
chown -R www-data:www-data "$AKAUNTING_DIR"

info "Configuration du site Apache"
cat > /etc/apache2/sites-available/akaunting.conf <<EOF
<VirtualHost *:80>
    ServerName ${AKAUNTING_DOMAIN}
    DocumentRoot ${AKAUNTING_DIR}

    <Directory ${AKAUNTING_DIR}>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/akaunting_error.log
    CustomLog \${APACHE_LOG_DIR}/akaunting_access.log combined
</VirtualHost>
EOF
a2enmod -q rewrite
a2ensite -q akaunting
a2dissite -q 000-default || true
apache2ctl configtest
service_restart apache2

open_ports 80/tcp

save_credentials /root/akaunting_identifiants.txt \
    "Base de données : ${AKAUNTING_DB_NAME}" \
    "Utilisateur     : ${AKAUNTING_DB_USER}" \
    "Mot de passe    : ${AKAUNTING_DB_PASS}"

IP="$(hostname -I | awk '{print $1}')"
echo
echo "✅ Akaunting est installé."
echo "Terminez l'installation dans le navigateur : http://${IP}/"
echo "Informations de base à saisir dans l'assistant : /root/akaunting_identifiants.txt"
