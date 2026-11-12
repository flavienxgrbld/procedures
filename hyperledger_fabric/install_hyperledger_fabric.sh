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

info "Hyperledger Fabric - Blockchain d'entreprise"

echo "=== Installation de Hyperledger Fabric ==="
pkg_install docker.io docker-compose curl git

# Service Docker
systemctl enable docker
systemctl start docker

# Installation Fabric
cd /opt
mkdir -p fabric
cd fabric

curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh | bash -s

echo
echo "✅ Hyperledger Fabric binaires téléchargés"
echo "Dossier: /opt/fabric"
echo "Testez avec: ./bin/fabric --version"
