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

info "Rustlings - Tutoriel interactif Rust"

echo "=== Installation de Rustlings ==="
pkg_install curl rustc

# Installation
curl -L https://raw.githubusercontent.com/rust-lang/rustlings/main/install.sh | bash

echo
echo "✅ Rustlings installé avec succès"
echo "Démarrez: rustlings"
