#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Plex Media Server - Serveur multimédia"

echo "=== Installation de Plex Media Server ==="
case "$PKG_MANAGER" in
    apt)
        wget -q https://downloads.plex.tv/plex-keys/PlexSign.key -O - | apt-key add -
        echo "deb https://downloads.plex.tv/repo/deb public main" > /etc/apt/sources.list.d/plexmediaserver.list
        pkg_update
        pkg_install plexmediaserver
        ;;
    dnf|yum)
        rpm -Uvh https://downloads.plex.tv/plex-keys/PlexSign.key >/dev/null 2>&1 || true
        echo "[PlexRepo]
name=PlexRepo
baseurl=https://downloads.plex.tv/repo/rpm/
gpgkey=https://downloads.plex.tv/plex-keys/PlexSign.key
gpgcheck=1
enabled=1" > /etc/yum.repos.d/plex.repo
        pkg_install plexmediaserver
        ;;
esac

systemctl enable plexmediaserver
systemctl start plexmediaserver

if command -v ufw >/dev/null 2>&1; then
    ufw allow 32400/tcp
fi

echo
echo "✅ Plex Media Server installé avec succès"
echo "URL: http://votre-serveur:32400"
echo "Port: 32400"
