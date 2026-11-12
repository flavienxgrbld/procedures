#!/usr/bin/env bash
# Installation de Matomo (archive officielle matomo-latest) sur Apache, PHP et MariaDB,
# avec l'archivage des rapports planifié.
#
# Variables modifiables :
#   MATOMO_DOMAIN   nom du site Apache (défaut : nom de la machine)

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

info "Matomo - Mesure d'audience web"

APP_DIR="/var/www/matomo"
MATOMO_DOMAIN="${MATOMO_DOMAIN:-$(hostname -f 2>/dev/null || hostname)}"
DB_PASS="$(random_password 24)"

pkg_update
pkg_install apache2 mariadb-server unzip curl php libapache2-mod-php php-mysql php-gd php-curl \
    php-xml php-mbstring php-zip php-intl
service_enable mariadb
service_restart mariadb

if [ -f "${APP_DIR}/config/config.ini.php" ]; then
    warn "Matomo est déjà configuré : fichiers conservés (mise à jour depuis l'interface)"
else
    mysql_create_db matomo matomo "$DB_PASS"
    TGZ="$(mktemp --suffix=.tar.gz)"; add_temp_file "$TGZ"
    download_file https://builds.matomo.org/matomo-latest.tar.gz "$TGZ"
    tar -xzf "$TGZ" -C /var/www/
    save_credentials /root/matomo_identifiants.txt "Base : matomo (hôte localhost)" "Utilisateur : matomo" "Mot de passe : ${DB_PASS}"
fi
chown -R www-data:www-data "$APP_DIR"

cat > /etc/apache2/sites-available/matomo.conf <<EOF
<VirtualHost *:80>
    ServerName ${MATOMO_DOMAIN}
    DocumentRoot ${APP_DIR}

    <Directory ${APP_DIR}>
        AllowOverride All
        Require all granted
    </Directory>
    # Dossiers à ne jamais servir
    <DirectoryMatch "${APP_DIR}/(config|tmp|lang)">
        Require all denied
    </DirectoryMatch>
</VirtualHost>
EOF
a2enmod -q rewrite
a2ensite -q matomo
a2dissite -q 000-default || true
apache2ctl configtest
service_restart apache2

# Archivage des rapports par cron (plus fiable que le déclenchement par les visites)
echo "5 * * * * www-data /usr/bin/php ${APP_DIR}/console core:archive --url=http://${MATOMO_DOMAIN}/ >/dev/null 2>&1" > /etc/cron.d/matomo
open_ports 80/tcp

echo
echo "✅ Matomo installé : http://$(primary_ip)/ (assistant ; base : /root/matomo_identifiants.txt)"
echo "Ensuite : Administration > Système > Paramètres généraux > désactiver l'archivage depuis le navigateur."
