#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Bacula - Système de sauvegarde d'entreprise"

echo "=== Installation de Bacula ==="
pkg_install bacula-director bacula-storage bacula-client bacula-console

# Configuration de base
mkdir -p /bacula/backup
chown -R bacula:bacula /bacula

# Services
systemctl enable bareos-dir
systemctl enable bareos-sd
systemctl enable bacula-fd

systemctl start bareos-dir
systemctl start bareos-sd
systemctl start bacula-fd

echo
echo "✅ Bacula installé avec succès"
echo "Configuration: /etc/bacula/"
echo "Nécessite une configuration avancée pour la production"
