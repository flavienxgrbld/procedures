#!/usr/bin/env bash

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
