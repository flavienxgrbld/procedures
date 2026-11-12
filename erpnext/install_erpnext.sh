#!/usr/bin/env bash
# Installation d'ERPNext 15 (Frappe Bench) en production : Nginx + Supervisor.
# Debian 12, Ubuntu 22.04 ou 24.04.
#
# Variables modifiables :
#   ERP_SITE        nom du site (défaut : erp.<domaine> ou nom de la machine)
#   ERP_BRANCH      branche Frappe/ERPNext (défaut : version-15)
#   ERP_ADMIN_PASS  mot de passe du compte Administrator (défaut : généré)
#   ERP_PRODUCTION  oui (Nginx + Supervisor, défaut) ou non (bench start à la main, port 8000)

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

info "ERPNext - Progiciel de gestion intégré"

case "${OS_ID}:${OS_VERSION_ID}" in
    debian:12|ubuntu:22.04|ubuntu:24.04) ;;
    *) error_exit "Système non pris en charge par ce script : ${OS_NAME} ${OS_VERSION_ID} (Debian 12, Ubuntu 22.04 ou 24.04)" ;;
esac

ERP_USER="frappe"
ERP_HOME="/home/${ERP_USER}"
ERP_BRANCH="${ERP_BRANCH:-version-15}"
ERP_SITE="${ERP_SITE:-$(hostname -f 2>/dev/null || hostname)}"
ERP_ADMIN_PASS="${ERP_ADMIN_PASS:-$(random_password 16)}"
ERP_PRODUCTION="${ERP_PRODUCTION:-oui}"
DB_ROOT_PASS="$(random_password 24)"
NODE_MAJOR="20"
BENCH_DIR="${ERP_HOME}/frappe-bench"

mem_mb=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
[ "$mem_mb" -ge 3800 ] || warn "Mémoire : ${mem_mb} Mo (4 Go conseillés)"

info "Dépendances système"
pkg_update
pkg_install git curl sudo python3-dev python3-pip python3-venv pipx redis-server \
    mariadb-server mariadb-client libmariadb-dev pkg-config xvfb libfontconfig wkhtmltopdf cron
if [ "$ERP_PRODUCTION" = "oui" ]; then
    pkg_install nginx supervisor
fi

info "MariaDB en utf8mb4 (exigé par Frappe)"
cat > /etc/mysql/mariadb.conf.d/99-frappe.cnf <<'EOF'
[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4
EOF
service_restart mariadb
# root garde l'accès par socket (sudo mysql) et reçoit un mot de passe pour bench
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket OR mysql_native_password USING PASSWORD('${DB_ROOT_PASS}'); FLUSH PRIVILEGES;"

info "Utilisateur ${ERP_USER}"
if ! id "$ERP_USER" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "$ERP_USER"
fi
chmod o+rx "$ERP_HOME"   # Nginx doit lire les fichiers statiques du bench

as_frappe() {
    sudo -u "$ERP_USER" -H bash -lc "export NVM_DIR=\$HOME/.nvm; [ -s \$NVM_DIR/nvm.sh ] && . \$NVM_DIR/nvm.sh; export PATH=\$HOME/.local/bin:\$PATH; $1"
}

info "Node.js ${NODE_MAJOR} et Yarn (nvm, pour l'utilisateur ${ERP_USER})"
NVM_VERSION="$(github_latest_tag nvm-sh/nvm v0.40.3)"
as_frappe "[ -s \$HOME/.nvm/nvm.sh ] || curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash"
as_frappe "nvm install ${NODE_MAJOR} && nvm alias default ${NODE_MAJOR} && npm install -g yarn"

info "Frappe Bench (pipx)"
as_frappe "pipx install frappe-bench || pipx upgrade frappe-bench"
as_frappe "bench --version"

if [ ! -d "${BENCH_DIR}/apps/frappe" ]; then
    info "Création du bench (${ERP_BRANCH}) - plusieurs minutes"
    as_frappe "cd \$HOME && bench init --frappe-branch ${ERP_BRANCH} frappe-bench"
fi

if [ ! -d "${BENCH_DIR}/apps/erpnext" ]; then
    info "Téléchargement de l'application ERPNext (${ERP_BRANCH})"
    as_frappe "cd ${BENCH_DIR} && bench get-app --branch ${ERP_BRANCH} erpnext"
fi

if [ ! -d "${BENCH_DIR}/sites/${ERP_SITE}" ]; then
    info "Création du site ${ERP_SITE} et installation d'ERPNext"
    as_frappe "cd ${BENCH_DIR} && bench new-site ${ERP_SITE} --db-root-password '${DB_ROOT_PASS}' --admin-password '${ERP_ADMIN_PASS}'"
    as_frappe "cd ${BENCH_DIR} && bench --site ${ERP_SITE} install-app erpnext"
    as_frappe "cd ${BENCH_DIR} && bench use ${ERP_SITE}"
fi

if [ "$ERP_PRODUCTION" = "oui" ]; then
    info "Mise en production (Nginx + Supervisor)"
    as_frappe "cd ${BENCH_DIR} && bench --site ${ERP_SITE} enable-scheduler && bench --site ${ERP_SITE} set-maintenance-mode off"
    BENCH_BIN="${ERP_HOME}/.local/bin/bench"
    NODE_BIN_DIR="$(as_frappe 'dirname "$(command -v node)"')"
    (cd "$BENCH_DIR" && PATH="${NODE_BIN_DIR}:${ERP_HOME}/.local/bin:${PATH}" "$BENCH_BIN" setup production "$ERP_USER" --yes)
    systemctl enable --now supervisor nginx
    service_restart supervisor
    service_restart nginx
    open_ports 80/tcp
    URL="http://${ERP_SITE}/"
else
    open_ports 8000/tcp
    URL="http://$(hostname -I | awk '{print $1}'):8000/ (après : sudo -iu ${ERP_USER} bash -lc 'cd frappe-bench && bench start')"
fi

save_credentials /root/erpnext_identifiants.txt \
    "Site                      : ${ERP_SITE}" \
    "Compte ERPNext            : Administrator" \
    "Mot de passe              : ${ERP_ADMIN_PASS}" \
    "Mot de passe root MariaDB : ${DB_ROOT_PASS}"

echo
echo "✅ ERPNext (${ERP_BRANCH}) installé"
echo "Adresse : ${URL}"
echo "Le nom ${ERP_SITE} doit être résolu par le DNS (ou /etc/hosts) des postes clients."
echo "Identifiants : /root/erpnext_identifiants.txt"
