#!/usr/bin/env bash
# Installation de PostgreSQL (paquets de la distribution, ou dépôt officiel PGDG),
# avec en option une base et un utilisateur dédiés et l'accès depuis le réseau local.
#
# Variables facultatives :
#   PG_PGDG=oui        utiliser le dépôt officiel PGDG (dernière version) - Debian/Ubuntu
#   PG_DB / PG_USER    base et utilisateur à créer (mot de passe généré)
#   PG_NETWORK=oui     écouter sur l'adresse du serveur et autoriser le réseau local (scram-sha-256)

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

info "PostgreSQL"

pkg_update
case "$PKG_MANAGER" in
    apt)
        if [ "${PG_PGDG:-non}" = "oui" ]; then
            pkg_install postgresql-common ca-certificates
            /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y
        fi
        pkg_install postgresql postgresql-contrib
        ;;
    dnf|yum)
        pkg_install postgresql-server postgresql-contrib
        [ -f /var/lib/pgsql/data/PG_VERSION ] || postgresql-setup --initdb
        ;;
    zypper)
        pkg_install postgresql-server postgresql-contrib
        ;;
    pacman)
        pkg_install postgresql
        [ -f /var/lib/postgres/data/PG_VERSION ] || sudo -u postgres initdb -D /var/lib/postgres/data
        ;;
esac
systemctl enable --now postgresql
check_service_status postgresql
psql --version

if [ -n "${PG_DB:-}" ] && [ -n "${PG_USER:-}" ]; then
    if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${PG_USER}'" | grep -q 1; then
        warn "L'utilisateur ${PG_USER} existe déjà : inchangé"
    else
        PG_PASS="$(random_password 24)"
        sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE USER \"${PG_USER}\" WITH PASSWORD '${PG_PASS}';"
        sudo -u postgres createdb --owner="$PG_USER" "$PG_DB"
        save_credentials "/root/postgresql_${PG_DB}.txt" "Base : ${PG_DB}" "Utilisateur : ${PG_USER}" "Mot de passe : ${PG_PASS}"
    fi
fi

if [ "${PG_NETWORK:-non}" = "oui" ]; then
    CONF="$(sudo -u postgres psql -tAc 'SHOW config_file')"
    HBA="$(sudo -u postgres psql -tAc 'SHOW hba_file')"
    IP="$(primary_ip)"
    LAN="$(ip -4 route show scope link 2>/dev/null | awk '!/docker|br-|veth/ {print $1; exit}')" || true
    [ -n "$LAN" ] || error_exit "Réseau local introuvable"
    backup_file "$CONF"; backup_file "$HBA"
    sed -i -E "s/^#?listen_addresses *=.*/listen_addresses = 'localhost,${IP}'/" "$CONF"
    target_db="${PG_DB:-all}"; target_user="${PG_USER:-all}"
    grep -qE "^host +${target_db} +${target_user} +${LAN//./\\.}" "$HBA" \
        || echo "host    ${target_db}    ${target_user}    ${LAN}    scram-sha-256" >> "$HBA"
    systemctl restart postgresql
    if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
        ufw allow from "$LAN" to any port 5432 proto tcp >/dev/null
    fi
    info "Accès réseau ouvert pour ${LAN} (base ${target_db}, utilisateur ${target_user})"
fi

echo
echo "✅ PostgreSQL installé"
echo "Console : sudo -u postgres psql"
