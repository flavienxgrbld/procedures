#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Nextcloud Talk - Visioconférence intégrée à Nextcloud"

echo "=== Installation de Nextcloud Talk ==="
echo "Nextcloud Talk s'installe via Nextcloud existant"
echo ""

# Vérifier si Nextcloud est installé
if [ ! -d "/var/www/nextcloud" ]; then
    echo "❌ Nextcloud n'est pas installé"
    echo "Installez d'abord Nextcloud avec: install_nextcloud.sh"
    exit 1
fi

# Activation via occ
cd /var/www/nextcloud
sudo -u www-data php occ app:install spreed
sudo -u www-data php occ app:enable spreed

# Configuration TURN server (optionnel)
sudo -u www-data php occ config:app:set spreed turn_servers --value='{"servers":[],"secret":"","protocols":"udp,tcp"}'

echo
echo "✅ Nextcloud Talk activé"
echo "Accédez via: http://votre-serveur/nextcloud"
