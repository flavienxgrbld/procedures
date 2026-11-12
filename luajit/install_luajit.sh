#!/usr/bin/env bash
# Installation de LuaJIT : paquet de la distribution (défaut) ou compilation
# depuis le dépôt officiel (LUAJIT_SOURCE=oui, dernière version de la branche v2.1).

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

info "LuaJIT - Compilateur à la volée pour Lua 5.1"

if [ "${LUAJIT_SOURCE:-non}" != "oui" ]; then
    pkg_update
    case "$PKG_MANAGER" in
        apt) pkg_install luajit libluajit-5.1-dev ;;
        dnf|yum) pkg_install luajit luajit-devel ;;
        zypper) pkg_install luajit luajit-devel ;;
        pacman) pkg_install luajit ;;
    esac
else
    info "Compilation depuis https://luajit.org/git/luajit.git (branche v2.1)"
    pkg_update
    case "$PKG_MANAGER" in
        apt) pkg_install build-essential git ;;
        dnf|yum) pkg_install gcc make git ;;
        zypper) pkg_install gcc make git ;;
        pacman) pkg_install base-devel git ;;
    esac
    SRC="$(mktemp -d)"
    add_temp_file "$SRC"
    git clone --depth 1 --branch v2.1 https://luajit.org/git/luajit.git "$SRC/luajit"
    make -C "$SRC/luajit" -j"$(nproc)"
    make -C "$SRC/luajit" install PREFIX=/usr/local
    ldconfig
fi

echo
echo "✅ $(luajit -v)"
