#!/usr/bin/env bash

set -euo pipefail

COMMON_SCRIPT="/tmp/install_common.sh"
if [ ! -f "$COMMON_SCRIPT" ]; then
    curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/install-scripts/main/root/common/install_common.sh" -o "$COMMON_SCRIPT"
fi
source "$COMMON_SCRIPT"

ensure_root
detect_os
detect_package_manager

info "Matrix Synapse - Serveur protocol collaboratif"

SYNAPSE_DIR="/opt/matrix"
SYNAPSE_USER="_matrix"

echo "=== Installation de Matrix Synapse ==="
pkg_install python3 python3-dev python3-pip libffi-dev libssl-dev libjpeg-dev libxml2-dev libxslt1-dev

# Installation base de données
install_database

# Création répertoire
mkdir -p "$SYNAPSE_DIR"
chown "$SYNAPSE_USER:$SYNAPSE_USER" "$SYNAPSE_DIR"

# Installation avec pip
pip3 install 'matrix-synapse[postgres]'

echo
echo "✅ Matrix Synapse en cours d'installation"
echo "Configuration requise:"
echo "  - Domaine"
echo "  - Base de données PostgreSQL"
echo "  - Certificat SSL"
echo "Commande: python -m synapse.app.homeserver --config-path $SYNAPSE_DIR/homeserver.yaml"
