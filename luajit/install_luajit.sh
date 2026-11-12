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

info "LuaJIT - Compilateur Just-In-Time Lua"

echo "=== Installation de LuaJIT ==="
pkg_install gcc make libreadline-dev

# Compilation
cd /tmp
git clone https://github.com/LuaJIT/LuaJIT.git
cd LuaJIT
make
make install

echo
echo "✅ LuaJIT installé avec succès"
echo "Testez avec: luajit -v"
