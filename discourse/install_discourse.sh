#!/usr/bin/env bash

set -euo pipefail

# Bibliothèque commune : copie du dépôt en priorité, téléchargement sinon.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/../install_common.sh"
if [ ! -f "$COMMON_SCRIPT" ]; then
    COMMON_SCRIPT="$(mktemp)"
    curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/install-scripts/main/root/common/install_common.sh" -o "$COMMON_SCRIPT"
fi
# shellcheck source=../install_common.sh
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
