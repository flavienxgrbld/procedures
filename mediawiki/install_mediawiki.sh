#!/usr/bin/env bash
# Installation de MediaWiki (version LTS) sur Apache, PHP et MariaDB, avec
# l'installateur en ligne de commande (LocalSettings.php généré automatiquement).
#
# Variables modifiables :
#   MW_VERSION     version LTS (défaut : 1.43.11)
#   MW_NAME        nom du wiki (défaut : Wiki)
#   MW_ADMIN       compte administrateur (défaut : Admin)
#   MW_ADMIN_PASS  mot de passe administrateur (défaut : généré)
#   MW_SERVER      adresse du wiki (défaut : http://<ip>)
#   MW_LANG        langue (défaut : fr)

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

info "MediaWiki - Moteur de wiki"

MW_VERSION="${MW_VERSION:-1.43.11}"
MW_BRANCH="${MW_VERSION%.*}"
APP_DIR="/var/www/mediawiki"
MW_NAME="${MW_NAME:-Wiki}"
MW_ADMIN="${MW_ADMIN:-Admin}"
MW_ADMIN_PASS="${MW_ADMIN_PASS:-$(random_password 16)}"
MW_SERVER="${MW_SERVER:-http://$(primary_ip)}"
MW_LANG="${MW_LANG:-fr}"
DB_PASS="$(random_password 24)"

pkg_update
pkg_install apache2 mariadb-server curl php libapache2-mod-php php-mysql php-xml php-mbstring \
    php-intl php-gd php-curl php-apcu
service_enable mariadb
service_restart mariadb

if [ -f "${APP_DIR}/LocalSettings.php" ]; then
    warn "MediaWiki est déjà configuré (${APP_DIR}/LocalSettings.php) : rien à faire"
    exit 0
fi

mysql_create_db wiki wiki "$DB_PASS"

info "Téléchargement de MediaWiki ${MW_VERSION}"
TGZ="$(mktemp --suffix=.tar.gz)"
add_temp_file "$TGZ"
download_file "https://releases.wikimedia.org/mediawiki/${MW_BRANCH}/mediawiki-${MW_VERSION}.tar.gz" "$TGZ"
mkdir -p "$APP_DIR"
tar -xzf "$TGZ" -C "$APP_DIR" --strip-components=1

info "Installation en ligne de commande (génère LocalSettings.php)"
php "${APP_DIR}/maintenance/run.php" install \
    --dbtype mysql --dbserver localhost --dbname wiki --dbuser wiki --dbpass "$DB_PASS" \
    --server "$MW_SERVER" --scriptpath "" --lang "$MW_LANG" \
    --pass "$MW_ADMIN_PASS" "$MW_NAME" "$MW_ADMIN"
chown -R www-data:www-data "$APP_DIR"
chmod 640 "${APP_DIR}/LocalSettings.php"

cat > /etc/apache2/sites-available/mediawiki.conf <<EOF
<VirtualHost *:80>
    ServerName $(hostname -f 2>/dev/null || hostname)
    DocumentRoot ${APP_DIR}

    <Directory ${APP_DIR}>
        AllowOverride All
        Require all granted
    </Directory>
    # Pas d'exécution de scripts dans les fichiers envoyés
    <Directory ${APP_DIR}/images>
        php_admin_flag engine off
        Options -Indexes
    </Directory>
</VirtualHost>
EOF
a2ensite -q mediawiki
a2dissite -q 000-default || true
apache2ctl configtest
service_restart apache2
open_ports 80/tcp

save_credentials /root/mediawiki_identifiants.txt \
    "Wiki : ${MW_SERVER}" "Administrateur : ${MW_ADMIN}" "Mot de passe : ${MW_ADMIN_PASS}" \
    "Base : wiki / utilisateur wiki / mot de passe ${DB_PASS}"

echo
echo "✅ MediaWiki ${MW_VERSION} installé : ${MW_SERVER}"
echo "Compte ${MW_ADMIN} : mot de passe dans /root/mediawiki_identifiants.txt"
