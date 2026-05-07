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

info "Jitsi Meet - Visioconférence open-source"

echo "=== Installation de Jitsi Meet ==="
pkg_install curl gnupg2 ntp

# Dépôt Jitsi
case "$PKG_MANAGER" in
    apt)
        curl https://download.jitsi.org/jitsi-key.gpg.key | apt-key add -
        sh -c 'echo "deb https://download.jitsi.org stable/" > /etc/apt/sources.list.d/jitsi-stable.list'
        pkg_update
        pkg_install jitsi-meet
        ;;
    dnf|yum)
        pkg_install jitsi-meet
        ;;
esac

if command -v ufw >/dev/null 2>&1; then
    ufw allow 443/tcp
    ufw allow 80/tcp
    ufw allow 10000:20000/udp
fi

echo
echo "✅ Jitsi Meet en cours d'installation"
echo "URL: https://votre-serveur"
echo "Ports: 80, 443, 10000-20000/udp"
