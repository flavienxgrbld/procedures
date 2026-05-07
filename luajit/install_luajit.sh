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
