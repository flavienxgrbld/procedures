#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "OpenHAB - Domotique universelle"

OPENHAB_DIR="/opt/openhab"
OPENHAB_USER="openhab"

echo "=== Installation d'OpenHAB ==="
pkg_install default-jre curl

# Création utilisateur
if ! id "$OPENHAB_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -m -d "$OPENHAB_DIR" -c "openHAB Service" "$OPENHAB_USER"
fi

# Téléchargement
cd /opt
OPENHAB_VERSION="4.0.2"
wget "https://github.com/openhab/openhab-distro/releases/download/${OPENHAB_VERSION}/openhab-${OPENHAB_VERSION}.zip"
unzip "openhab-${OPENHAB_VERSION}.zip"
rm "openhab-${OPENHAB_VERSION}.zip"

chown -R "$OPENHAB_USER:$OPENHAB_USER" "$OPENHAB_DIR"

# Service systemd
cat > /etc/systemd/system/openhab.service <<'EOF'
[Unit]
Description=openHAB Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=openhab
Group=openhab
WorkingDirectory=/opt/openhab
ExecStart=/opt/openhab/start.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openhab
systemctl start openhab

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8080/tcp
    ufw allow 8443/tcp
fi

echo
echo "✅ openHAB en cours d'installation"
echo "URL: http://votre-serveur:8080"
