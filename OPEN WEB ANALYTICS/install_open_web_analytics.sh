#!/usr/bin/env bash
# Installation d'Open Web Analytics (archive « packaged » officielle) sur Apache, PHP et MariaDB.
#
# Variables modifiables :
#   OWA_VERSION  version (défaut : 1.14.6)
#   OWA_DOMAIN   nom du site Apache (défaut : nom de la machine)

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

info "Open Web Analytics - Mesure d'audience"

OWA_VERSION="${OWA_VERSION:-1.14.6}"
OWA_DOMAIN="${OWA_DOMAIN:-$(hostname -f 2>/dev/null || hostname)}"
APP_DIR="/var/www/owa"
DB_PASS="$(random_password 24)"

pkg_update
pkg_install apache2 mariadb-server curl php libapache2-mod-php php-mysql php-curl php-xml php-mbstring php-gd
service_enable mariadb
service_restart mariadb

if [ -f "${APP_DIR}/owa-config.php" ]; then
    warn "OWA est déjà configuré : fichiers conservés"
else
    mysql_create_db owa owa "$DB_PASS"
    TAR="$(mktemp --suffix=.tar)"; add_temp_file "$TAR"
    download_file "https://github.com/Open-Web-Analytics/Open-Web-Analytics/releases/download/${OWA_VERSION}/owa_${OWA_VERSION}_packaged.tar" "$TAR"
    mkdir -p "$APP_DIR"
    tar -xf "$TAR" -C "$APP_DIR"
    save_credentials /root/owa_identifiants.txt "Base : owa (hôte localhost)" "Utilisateur : owa" "Mot de passe : ${DB_PASS}"
fi
chown -R www-data:www-data "$APP_DIR"

cat > /etc/apache2/sites-available/owa.conf <<EOF
<VirtualHost *:80>
    ServerName ${OWA_DOMAIN}
    DocumentRoot ${APP_DIR}

    <Directory ${APP_DIR}>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
a2enmod -q rewrite
a2ensite -q owa
a2dissite -q 000-default || true
apache2ctl configtest
service_restart apache2
open_ports 80/tcp

echo
echo "✅ OWA ${OWA_VERSION} installé : http://$(primary_ip)/install.php (base : /root/owa_identifiants.txt)"
