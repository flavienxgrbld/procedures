#!/usr/bin/env bash
# Installation de Bacula (Director, Storage Daemon, File Daemon, console)
# sur un serveur Debian/Ubuntu, avec catalogue MariaDB.
#
# Variables modifiables :
#   BACULA_STORAGE_DIR  dossier des volumes de sauvegarde (défaut : /bacula/backup)

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

info "Bacula - Système de sauvegarde d'entreprise"

BACULA_STORAGE_DIR="${BACULA_STORAGE_DIR:-/bacula/backup}"

info "Installation de MariaDB (catalogue)"
pkg_update
pkg_install mariadb-server debconf-utils
service_enable mariadb
service_restart mariadb

info "Préconfiguration de dbconfig-common (création automatique de la base du catalogue)"
debconf-set-selections <<'EOF'
bacula-director-mysql bacula-director-mysql/dbconfig-install boolean true
bacula-director-mysql bacula-director-mysql/mysql/method select Unix socket
EOF

info "Installation des composants Bacula"
pkg_install bacula-director-mysql bacula-director bacula-sd bacula-fd bacula-console

info "Dossier des sauvegardes : ${BACULA_STORAGE_DIR}"
mkdir -p "$BACULA_STORAGE_DIR"
chown -R bacula:bacula "$BACULA_STORAGE_DIR"
chmod 750 "$BACULA_STORAGE_DIR"

SD_CONF="/etc/bacula/bacula-sd.conf"
backup_file "$SD_CONF"
if grep -qE 'Archive Device = /nonexistent' "$SD_CONF"; then
    sed -i -E "s#Archive Device = /nonexistent[^[:space:]]*#Archive Device = ${BACULA_STORAGE_DIR}#" "$SD_CONF"
    info "Archive Device du Storage Daemon pointé vers ${BACULA_STORAGE_DIR}"
else
    warn "Aucun « Archive Device = /nonexistent... » trouvé dans ${SD_CONF} : vérifier le bloc Device à la main"
fi

info "Vérification de la syntaxe des configurations"
bacula-dir -t -c /etc/bacula/bacula-dir.conf
bacula-sd -t -c "$SD_CONF"
bacula-fd -t -c /etc/bacula/bacula-fd.conf

info "Démarrage des services"
for svc in bacula-director bacula-sd bacula-fd; do
    systemctl enable "$svc"
    systemctl restart "$svc"
done
sleep 2
for svc in bacula-director bacula-sd bacula-fd; do
    check_service_status "$svc"
done

echo
echo "✅ Bacula installé (Director, Storage Daemon, File Daemon)"
echo "Volumes de sauvegarde : ${BACULA_STORAGE_DIR}"
echo "Console               : sudo bconsole  (puis « label », « run », « status director »)"
echo "Configuration         : /etc/bacula/ (adapter FileSet et Job dans bacula-dir.conf)"
