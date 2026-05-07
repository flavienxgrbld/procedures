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

info "Netdata - Monitoring système temps réel"

echo "=== Installation de Netdata ==="
perl_version=$(perl -v | grep version | awk '{print $NF}')

case "$PKG_MANAGER" in
    apt)
        pkg_install curl git zlib1g-dev uuid-dev libuv1-dev liblz4-dev libssl-dev libelf-dev autoconf automake libtool
        ;;
    dnf|yum)
        pkg_install curl git zlib-devel libuv-devel lz4-devel openssl-devel elfutils-libelf-devel
        ;;
esac

cd /opt
git clone https://github.com/netdata/netdata.git --depth=100 || true
cd netdata

./packaging/installer/install.sh --stable-channel --disable-telemetry

if command -v ufw >/dev/null 2>&1; then
    ufw allow 19999/tcp
fi

echo
echo "✅ Netdata installé avec succès"
echo "URL: http://votre-serveur:19999"
