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

info "MongoDB - Base de données NoSQL"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

echo "=== Installation de MongoDB ==="
case "$PKG_MANAGER" in
    apt)
        # Ajout du dépôt MongoDB
        curl -fsSL https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add -
        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-5.0.list
        pkg_update
        pkg_install mongodb-org
        ;;
    dnf)
        cat > /etc/yum.repos.d/mongodb-org-5.0.repo <<'EOF'
[mongodb-org-5.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/5.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-5.0.asc
EOF
        pkg_install mongodb-org
        ;;
    zypper)
        pkg_install mongodb
        ;;
    pacman)
        pkg_install mongodb
        ;;
esac

systemctl enable mongod
systemctl start mongod

if command -v ufw >/dev/null 2>&1; then
    ufw allow 27017/tcp
fi

echo
echo "✅ MongoDB installé avec succès"
echo "Port: 27017"
