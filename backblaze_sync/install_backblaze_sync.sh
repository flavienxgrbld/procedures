#!/usr/bin/env bash

set -euo pipefail

# Bibliothèque commune : copie du dépôt en priorité, téléchargement sinon.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/../install_common.sh"
if [ ! -f "$COMMON_SCRIPT" ]; then
    COMMON_SCRIPT="$(mktemp)"
    curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/install-scripts/main/root/common/install_common.sh" -o "$COMMON_SCRIPT"
fi
# shellcheck source=../install_common.sh
source "$COMMON_SCRIPT"

ensure_root
detect_os
detect_package_manager

info "SyncThing - Synchronisation P2P décentralisée"

echo "=== Installation de Syncthing ==="
case "$PKG_MANAGER" in
    apt)
        curl -s -o - https://syncthing.net/release-key.txt | apt-key add -
        echo "deb https://apt.syncthing.net/ syncthing stable" | tee /etc/apt/sources.list.d/syncthing.list
        pkg_update
        pkg_install syncthing
        ;;
    dnf|yum)
        pkg_install syncthing
        ;;
esac

# Service
systemctl enable syncthing@root
systemctl start syncthing@root

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8384/tcp
    ufw allow 22000/tcp
    ufw allow 21027/udp
    ufw allow 21025/tcp
    ufw allow 21026/tcp
fi

echo
echo "✅ Syncthing installé avec succès"
echo "Interface Web: http://localhost:8384"
echo "Ports: 22000/tcp (sync), 21027/udp (discovery)"
