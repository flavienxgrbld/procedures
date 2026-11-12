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

info "Hurl - Tester les API REST"

echo "=== Installation de Hurl ==="
pkg_install curl

# Installation
HURL_VERSION="4.1.0"
curl --proto '=https' -tlsv1.2 -sSf https://raw.githubusercontent.com/Orange-OpenSource/hurl/master/install.sh | bash

echo
echo "✅ Hurl installé avec succès"
echo "Créez des fichiers .hurl pour tester vos APIs"
echo "Exécutez avec: hurl test.hurl"
