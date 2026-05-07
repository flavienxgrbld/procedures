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

info "Emby Media Server - Serveur streaming vidéo"

echo "=== Installation d'Emby Media Server ==="
case "$PKG_MANAGER" in
    apt)
        curl https://packages.emby.media/emby-key.gpg | apt-key add -
        echo "deb https://packages.emby.media/emby/ all main" > /etc/apt/sources.list.d/emby.list
        pkg_update
        pkg_install emby-server
        ;;
    dnf|yum)
        rpm --import https://packages.emby.media/emby-key.gpg >/dev/null 2>&1 || true
        echo "[emby-release]
name=Emby-release
baseurl=https://packages.emby.media/emby/
gpgkey=https://packages.emby.media/emby-key.gpg
gpgcheck=1" > /etc/yum.repos.d/emby.repo
        pkg_install emby-server
        ;;
esac

systemctl enable emby-server
systemctl start emby-server

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8096/tcp
fi

echo
echo "✅ Emby Media Server installé avec succès"
echo "URL: http://votre-serveur:8096"
