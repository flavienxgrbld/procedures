#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "ERPNext - ERP/CRM complet"

ERPNEXT_DIR="/opt/erpnext"
ERPNEXT_USER="erpnext"

echo "=== Installation d'ERPNext ==="
pkg_install python3 python3-dev python3-pip python3-venv git redis-server mariadb-server curl

# Création utilisateur
if ! id "$ERPNEXT_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -m -d "$ERPNEXT_DIR" -c "ERPNext Service" "$ERPNEXT_USER"
fi

# Installation Frappe CLI
pip3 install frappe-bench

# Création bench
su - $ERPNEXT_USER -c "bench init erpnext-bench --frappe-branch version-14"

cd "$ERPNEXT_DIR/erpnext-bench"
su - $ERPNEXT_USER -c "bench new-site erpnext.local"
su - $ERPNEXT_USER -c "bench get-app erpnext"
su - $ERPNEXT_USER -c "bench install-app erpnext"

echo
echo "✅ ERPNext en cours d'installation"
echo "Démarrage: cd $ERPNEXT_DIR/erpnext-bench && bench start"
