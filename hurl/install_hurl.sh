#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

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
