#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

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
