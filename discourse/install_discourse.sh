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

info "Discourse - Forum moderne et intuitif"

DISCOURSE_DIR="/var/discourse"

echo "=== Installation de Discourse ==="
echo "Discourse est optimisé pour Docker"
echo ""

pkg_install docker.io docker-compose git

mkdir -p $DISCOURSE_DIR
cd $DISCOURSE_DIR

# Clone containers
git clone https://github.com/discourse/discourse_docker.git || true
cd discourse_docker

# Configuration initiale
./discourse-setup

echo
echo "✅ Discourse en cours d'installation"
echo "Suivez l'assistant de configuration"
