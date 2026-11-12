#!/usr/bin/env bash
# Installation de Cacti avec le paquet Debian/Ubuntu (Apache, PHP, MariaDB,
# tâche de collecte), sans question grâce à la préconfiguration debconf.
#
# Variables modifiables :
#   CACTI_TIMEZONE  fuseau horaire de PHP et MariaDB (défaut : celui du système)

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

info "Cacti - Supervision SNMP et graphiques"

CACTI_TIMEZONE="${CACTI_TIMEZONE:-$(timedatectl show -p Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo UTC)}"

info "Installation de MariaDB"
pkg_update
pkg_install mariadb-server debconf-utils
service_enable mariadb
service_restart mariadb

info "Préconfiguration du paquet cacti"
debconf-set-selections <<'EOF'
cacti cacti/webserver select apache2
cacti cacti/dbconfig-install boolean true
cacti cacti/mysql/method select Unix socket
EOF

info "Installation de Cacti, SNMP et RRDtool"
pkg_install cacti snmp snmpd rrdtool

PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
info "Réglages PHP ${PHP_VERSION} recommandés par Cacti (fuseau : ${CACTI_TIMEZONE})"
for sapi in apache2 cli; do
    if [ -d "/etc/php/${PHP_VERSION}/${sapi}/conf.d" ]; then
        cat > "/etc/php/${PHP_VERSION}/${sapi}/conf.d/99-cacti.ini" <<EOF
date.timezone = ${CACTI_TIMEZONE}
memory_limit = 512M
max_execution_time = 60
EOF
    fi
done

info "Fuseaux horaires MariaDB (contrôle de l'assistant Cacti)"
mysql_tzinfo_to_sql /usr/share/zoneinfo 2>/dev/null | mysql -u root mysql
mysql -u root -e "GRANT SELECT ON mysql.time_zone_name TO 'cacti'@'localhost'; FLUSH PRIVILEGES;"
cat > /etc/mysql/mariadb.conf.d/99-cacti.cnf <<EOF
[mysqld]
default-time-zone = '${CACTI_TIMEZONE}'
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
EOF

service_restart mariadb
service_restart apache2
check_service_status apache2

open_ports 80/tcp

echo
echo "✅ Cacti installé"
echo "Interface : http://$(hostname -I | awk '{print $1}')/cacti"
echo "Connexion : admin / admin (changement de mot de passe imposé), puis suivre l'assistant"
