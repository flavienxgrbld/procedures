#!/usr/bin/env bash
# Installation de Ghost en production selon la méthode officielle :
# Ubuntu, Nginx, MySQL 8, Node.js 22 et Ghost-CLI (sans question).
#
# Variables :
#   GHOST_URL        adresse publique du blog, ex. https://blog.exemple.fr (obligatoire)
#   GHOST_SSL_EMAIL  e-mail pour Let's Encrypt (obligatoire si GHOST_URL commence par https://)
#   GHOST_OS_USER    compte d'administration qui lance Ghost-CLI (défaut : ghostadmin ; « ghost » est interdit)

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

info "Ghost - Plateforme de publication"

[ "$OS_ID" = "ubuntu" ] || error_exit "Ghost ne prend en charge officiellement qu'Ubuntu (22.04 ou 24.04)"
[ -n "${GHOST_URL:-}" ] || error_exit "Définir GHOST_URL, par exemple : sudo GHOST_URL=https://blog.exemple.fr GHOST_SSL_EMAIL=admin@exemple.fr bash install_ghost.sh"
GHOST_OS_USER="${GHOST_OS_USER:-ghostadmin}"
[ "$GHOST_OS_USER" != "ghost" ] || error_exit "Le nom « ghost » est réservé à Ghost-CLI"
case "$GHOST_URL" in
    https://*) [ -n "${GHOST_SSL_EMAIL:-}" ] || error_exit "GHOST_SSL_EMAIL est obligatoire avec une adresse https://" ; SSL_OPTS=(--sslemail "$GHOST_SSL_EMAIL") ;;
    http://*)  SSL_OPTS=(--no-setup-ssl) ;;
    *) error_exit "GHOST_URL doit commencer par http:// ou https://" ;;
esac

GHOST_DIR="/var/www/ghost"
DB_NAME="ghost_prod"; DB_USER="ghost_db"
DB_PASS="$(random_password 24)"
NODE_MAJOR="22"

info "Nginx et MySQL 8"
pkg_update
pkg_install nginx mysql-server curl ca-certificates gnupg sudo
systemctl enable --now nginx mysql

info "Base ${DB_NAME} et utilisateur MySQL dédié"
mysql -u root <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL

if ! command -v node >/dev/null 2>&1 || [ "$(node -p 'process.versions.node.split(".")[0]')" != "$NODE_MAJOR" ]; then
    info "Node.js ${NODE_MAJOR} (dépôt NodeSource, recommandé par Ghost)"
    NS="$(mktemp)"
    add_temp_file "$NS"
    download_file "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" "$NS"
    bash "$NS"
    pkg_install nodejs
fi
node -v

info "Ghost-CLI"
npm install -g ghost-cli@latest

info "Compte d'administration ${GHOST_OS_USER}"
if ! id "$GHOST_OS_USER" >/dev/null 2>&1; then
    useradd -m -s /bin/bash -G sudo "$GHOST_OS_USER"
fi
# Ghost-CLI appelle sudo : autorisation temporaire sans mot de passe, retirée à la fin
SUDOERS_TMP="/etc/sudoers.d/90-ghost-install"
echo "${GHOST_OS_USER} ALL=(ALL) NOPASSWD:ALL" > "$SUDOERS_TMP"
chmod 440 "$SUDOERS_TMP"
add_temp_file "$SUDOERS_TMP"

mkdir -p "$GHOST_DIR"
chown "${GHOST_OS_USER}:${GHOST_OS_USER}" "$GHOST_DIR"
chmod 775 "$GHOST_DIR"

if [ -f "${GHOST_DIR}/config.production.json" ]; then
    warn "Ghost est déjà installé dans ${GHOST_DIR} : mise à jour avec « ghost update »"
    sudo -u "$GHOST_OS_USER" -H bash -c "cd ${GHOST_DIR} && ghost update"
else
    info "Installation de Ghost (${GHOST_URL})"
    sudo -u "$GHOST_OS_USER" -H bash -c "cd ${GHOST_DIR} && ghost install --no-prompt \
        --url '${GHOST_URL}' --db mysql --dbhost localhost \
        --dbuser '${DB_USER}' --dbpass '${DB_PASS}' --dbname '${DB_NAME}' --no-setup-mysql \
        --process systemd --start ${SSL_OPTS[*]}"
fi

open_ports 80/tcp 443/tcp

save_credentials /root/ghost_identifiants.txt \
    "Base MySQL : ${DB_NAME}" "Utilisateur : ${DB_USER}" "Mot de passe : ${DB_PASS}" \
    "Compte système d'administration : ${GHOST_OS_USER} (définir son mot de passe : sudo passwd ${GHOST_OS_USER})"

echo
echo "✅ Ghost installé"
echo "Créer le compte propriétaire : ${GHOST_URL%/}/ghost/"
echo "Maintenance : sudo -iu ${GHOST_OS_USER}, puis cd ${GHOST_DIR} && ghost update / ghost ls / ghost log"
