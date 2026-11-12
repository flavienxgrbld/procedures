#!/usr/bin/env bash
# Installation de Dolibarr (dernière version stable) sur Apache, PHP et MariaDB.
#
# Variables modifiables :
#   DOLIBARR_VERSION  version à installer (défaut : dernière publiée sur GitHub)
#   DOLIBARR_DOMAIN   nom du site Apache (défaut : nom de la machine)
#   DOLIBARR_DB_PASS  mot de passe de la base (défaut : généré)

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

info "Dolibarr - ERP/CRM"

DOLI_DIR="/var/www/dolibarr"
DOCS_DIR="/var/lib/dolibarr/documents"
DOLIBARR_VERSION="${DOLIBARR_VERSION:-$(github_latest_tag Dolibarr/dolibarr 24.0.3)}"
DOLIBARR_DOMAIN="${DOLIBARR_DOMAIN:-$(hostname -f 2>/dev/null || hostname)}"
DB_NAME="dolibarr"; DB_USER="dolibarr"
DOLIBARR_DB_PASS="${DOLIBARR_DB_PASS:-$(random_password 24)}"

pkg_update
pkg_install apache2 mariadb-server curl php libapache2-mod-php php-mysql php-gd php-xml php-zip \
    php-intl php-curl php-mbstring php-soap
pkg_install php-imap || warn "php-imap indisponible (retiré de PHP 8.4) : seule la collecte d'e-mails IMAP sera inactive"
service_enable mariadb
service_restart mariadb

info "Base de données ${DB_NAME}"
mysql_create_db "$DB_NAME" "$DB_USER" "$DOLIBARR_DB_PASS"

if [ -f "${DOLI_DIR}/htdocs/index.php" ]; then
    warn "Dolibarr est déjà présent dans ${DOLI_DIR} : fichiers conservés"
else
    info "Téléchargement de Dolibarr ${DOLIBARR_VERSION}"
    TGZ="$(mktemp --suffix=.tar.gz)"
    add_temp_file "$TGZ"
    download_file "https://github.com/Dolibarr/dolibarr/archive/refs/tags/${DOLIBARR_VERSION}.tar.gz" "$TGZ"
    mkdir -p "$DOLI_DIR"
    tar -xzf "$TGZ" -C "$DOLI_DIR" --strip-components=1
    touch "${DOLI_DIR}/htdocs/conf/conf.php"
fi
mkdir -p "$DOCS_DIR"
chown -R www-data:www-data "$DOLI_DIR" /var/lib/dolibarr

cat > /etc/apache2/sites-available/dolibarr.conf <<EOF
<VirtualHost *:80>
    ServerName ${DOLIBARR_DOMAIN}
    DocumentRoot ${DOLI_DIR}/htdocs

    <Directory ${DOLI_DIR}/htdocs>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/dolibarr_error.log
    CustomLog \${APACHE_LOG_DIR}/dolibarr_access.log combined
</VirtualHost>
EOF
a2ensite -q dolibarr
a2dissite -q 000-default || true
apache2ctl configtest
service_restart apache2

open_ports 80/tcp

save_credentials /root/dolibarr_identifiants.txt \
    "Répertoire des documents : ${DOCS_DIR}" \
    "Base de données          : ${DB_NAME} (serveur localhost)" \
    "Utilisateur              : ${DB_USER}" \
    "Mot de passe             : ${DOLIBARR_DB_PASS}"

IP="$(hostname -I | awk '{print $1}')"
echo
echo "✅ Dolibarr ${DOLIBARR_VERSION} installé"
echo "1. Assistant : http://${IP}/install/ (informations dans /root/dolibarr_identifiants.txt)"
echo "2. Ensuite, verrouiller :"
echo "   sudo touch ${DOCS_DIR}/install.lock && sudo chmod 444 ${DOLI_DIR}/htdocs/conf/conf.php"
