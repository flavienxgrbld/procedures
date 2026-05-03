#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

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
