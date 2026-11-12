#!/usr/bin/env bash
# Installation de DokuWiki (version stable officielle) sur Apache et PHP.
#
# Variables modifiables :
#   DOKUWIKI_DOMAIN  nom du site Apache (défaut : nom de la machine)

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

info "DokuWiki - Wiki sans base de données"

WIKI_DIR="/var/www/dokuwiki"
DOKUWIKI_DOMAIN="${DOKUWIKI_DOMAIN:-$(hostname -f 2>/dev/null || hostname)}"

pkg_update
pkg_install apache2 php libapache2-mod-php php-xml php-mbstring php-gd php-intl php-zip curl

if [ -f "${WIKI_DIR}/doku.php" ]; then
    warn "DokuWiki est déjà présent dans ${WIKI_DIR} : fichiers conservés (mise à jour : extension Upgrade)"
else
    info "Téléchargement de la version stable"
    TGZ="$(mktemp --suffix=.tgz)"
    add_temp_file "$TGZ"
    download_file https://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz "$TGZ"
    mkdir -p "$WIKI_DIR"
    tar -xzf "$TGZ" -C "$WIKI_DIR" --strip-components=1
fi
chown -R www-data:www-data "$WIKI_DIR"

cat > /etc/apache2/sites-available/dokuwiki.conf <<EOF
<VirtualHost *:80>
    ServerName ${DOKUWIKI_DOMAIN}
    DocumentRoot ${WIKI_DIR}

    <Directory ${WIKI_DIR}>
        AllowOverride All
        Require all granted
    </Directory>

    # Interdire l'accès direct aux dossiers sensibles
    <LocationMatch "/(data|conf|bin|inc|vendor)/">
        Require all denied
    </LocationMatch>

    ErrorLog \${APACHE_LOG_DIR}/dokuwiki_error.log
    CustomLog \${APACHE_LOG_DIR}/dokuwiki_access.log combined
</VirtualHost>
EOF
a2enmod -q rewrite
a2ensite -q dokuwiki
a2dissite -q 000-default || true
apache2ctl configtest
service_restart apache2

open_ports 80/tcp

IP="$(hostname -I | awk '{print $1}')"
echo
echo "✅ DokuWiki installé dans ${WIKI_DIR}"
echo "1. Terminer l'installation : http://${IP}/install.php"
echo "2. Puis supprimer l'assistant : sudo rm ${WIKI_DIR}/install.php"
