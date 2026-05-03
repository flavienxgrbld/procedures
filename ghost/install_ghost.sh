#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Ghost - Plateforme de blog moderne"

GHOST_DIR="/opt/ghost"
GHOST_USER="ghost"

echo "=== Installation de Ghost ==="
pkg_install python3 curl

# Installation Node.js
case "$PKG_MANAGER" in
    apt)
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        pkg_install nodejs
        ;;
    dnf|yum)
        pkg_install nodejs npm
        ;;
esac

# Installation Ghost CLI
npm install -g ghost-cli

# Création utilisateur
if ! id "$GHOST_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -m -d "$GHOST_DIR" -c "Ghost Service" "$GHOST_USER"
fi

mkdir -p "$GHOST_DIR"
chown -R "$GHOST_USER:$GHOST_USER" "$GHOST_DIR"

# Installation Ghost
cd "$GHOST_DIR"
sudo -u "$GHOST_USER" ghost install

echo
echo "✅ Ghost en cours d'installation"
echo "Suivez les instructions d'installation"
