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

info "Syncthing - Synchronisation distribuée P2P"

echo "=== Installation de Syncthing ==="
case "$PKG_MANAGER" in
    apt)
        curl -s -o - https://syncthing.net/release-key.txt | apt-key add -
        echo "deb https://apt.syncthing.net/ syncthing stable" > /etc/apt/sources.list.d/syncthing.list
        pkg_update
        pkg_install syncthing
        ;;
    dnf|yum)
        pkg_install syncthing
        ;;
    zypper)
        pkg_install syncthing
        ;;
    pacman)
        pkg_install syncthing
        ;;
esac

# Service
systemctl enable syncthing@$USER
systemctl start syncthing@$USER

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8384/tcp
    ufw allow 22000/tcp
    ufw allow 21027/udp
fi

echo
echo "✅ Syncthing installé avec succès"
echo "URL Web: http://localhost:8384"
echo "Port de synchronisation: 22000/tcp"
echo "Port discovery: 21027/udp"
