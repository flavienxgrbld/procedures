#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "PostgreSQL - Base de données relationnelle puissante"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

echo "=== Installation de PostgreSQL ==="
case "$PKG_MANAGER" in
    apt)
        pkg_install postgresql postgresql-contrib postgresql-client
        ;;
    dnf|yum)
        pkg_install postgresql-server postgresql-contrib postgresql-devel
        postgresql-setup initdb 2>/dev/null || postgresql-setup --initdb
        ;;
    zypper)
        pkg_install postgresql-server postgresql-client postgresql-contrib
        ;;
    pacman)
        pkg_install postgresql
        sudo -u postgres initdb -D /var/lib/postgres/data 2>/dev/null || true
        ;;
esac

# Démarrage du service
systemctl enable postgresql
systemctl start postgresql

# Configuration de sécurité
read -sp "Mot de passe pour l'utilisateur postgres: " POSTGRES_PASS
echo

sudo -u postgres psql <<EOSQL
ALTER USER postgres WITH PASSWORD '${POSTGRES_PASS}';
EOSQL

# Configuration firewall
if command -v ufw >/dev/null 2>&1; then
    ufw allow 5432/tcp
fi

echo
echo "✅ PostgreSQL installé avec succès"
echo "Port: 5432"
echo "Utilisateur: postgres"
echo "Mot de passe défini à la création"
