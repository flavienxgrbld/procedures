#!/usr/bin/env bash
# Installation de GitList (archive de version officielle) sur Apache et PHP.
#
# Variables modifiables :
#   GITLIST_REPOS   dossier contenant les dépôts Git à afficher (défaut : /srv/git)
#   GITLIST_DOMAIN  nom du site Apache (défaut : nom de la machine)
#   GITLIST_USER / GITLIST_PASS  protection par mot de passe (facultatif, recommandé)

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

info "GitList - Interface web en lecture seule pour dépôts Git"

# 2.0.1 est la dernière version publiée avec son archive gitlist-<version>.zip
# (le tag 2.0.2 n'en a pas ; l'archive des sources ne convient pas).
GITLIST_VERSION="2.0.1"
APP_DIR="/var/www/gitlist"
GITLIST_REPOS="${GITLIST_REPOS:-/srv/git}"
GITLIST_DOMAIN="${GITLIST_DOMAIN:-$(hostname -f 2>/dev/null || hostname)}"

pkg_update
pkg_install apache2 php libapache2-mod-php php-xml php-mbstring git unzip curl apache2-utils

info "Téléchargement de GitList ${GITLIST_VERSION}"
ZIP="$(mktemp --suffix=.zip)"
add_temp_file "$ZIP"
download_file "https://github.com/klaussilveira/gitlist/releases/download/${GITLIST_VERSION}/gitlist-${GITLIST_VERSION}.zip" "$ZIP"
mkdir -p "$APP_DIR"
unzip -oq "$ZIP" -d "$APP_DIR"

mkdir -p "$GITLIST_REPOS"
sed -i -E "s#^(\s*default_repository_dir:).*#\1 ${GITLIST_REPOS}#" "${APP_DIR}/config/config.yml"
chmod -R o+rX "$GITLIST_REPOS"
# Git refuse de lire des dépôts appartenant à un autre utilisateur que www-data
git config --system --get-all safe.directory | grep -qx '\*' || git config --system --add safe.directory '*'

mkdir -p "${APP_DIR}/var/cache" "${APP_DIR}/var/log"
chown -R www-data:www-data "${APP_DIR}/var"

AUTH_BLOCK=""
if [ -n "${GITLIST_USER:-}" ] && [ -n "${GITLIST_PASS:-}" ]; then
    htpasswd -bcB /etc/apache2/gitlist.htpasswd "$GITLIST_USER" "$GITLIST_PASS" >/dev/null
    chown root:www-data /etc/apache2/gitlist.htpasswd
    chmod 640 /etc/apache2/gitlist.htpasswd
    AUTH_BLOCK='        AuthType Basic
        AuthName "GitList"
        AuthUserFile /etc/apache2/gitlist.htpasswd
        Require valid-user'
else
    AUTH_BLOCK='        Require all granted'
    warn "Aucune authentification : tous les dépôts de ${GITLIST_REPOS} seront visibles (définir GITLIST_USER et GITLIST_PASS)"
fi

cat > /etc/apache2/sites-available/gitlist.conf <<EOF
<VirtualHost *:80>
    ServerName ${GITLIST_DOMAIN}
    DocumentRoot ${APP_DIR}/public

    <Directory ${APP_DIR}/public>
        AllowOverride All
${AUTH_BLOCK}
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/gitlist_error.log
    CustomLog \${APACHE_LOG_DIR}/gitlist_access.log combined
</VirtualHost>
EOF
a2enmod -q rewrite
a2ensite -q gitlist
a2dissite -q 000-default || true
apache2ctl configtest
service_restart apache2
open_ports 80/tcp

echo
echo "✅ GitList ${GITLIST_VERSION} installé : http://$(hostname -I | awk '{print $1}')/"
echo "Dépôts affichés : ${GITLIST_REPOS} (ex. sudo git clone --bare <url> ${GITLIST_REPOS}/projet.git)"
