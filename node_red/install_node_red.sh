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

info "Node-RED - Programmation visuelle pour l'automation"

echo "=== Installation de Node-RED ==="
pkg_install build-essential python3

# Installation Node.js
case "$PKG_MANAGER" in
    apt)
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        pkg_install nodejs
        ;;
all)
        pkg_install nodejs npm
        ;;
esac

# Installation Node-RED globalement
npm install -g --unsafe-perm node-red

# Service systemd
cat > /etc/systemd/system/node-red.service <<'EOF'
[Unit]
Description=Node-RED
After=syslog.target network.target

[Service]
ExecStart=/usr/bin/node-red-pi
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node-red
systemctl start node-red

if command -v ufw >/dev/null 2>&1; then
    ufw allow 1880/tcp
fi

echo
echo "✅ Node-RED installé avec succès"
echo "URL: http://votre-serveur:1880"
