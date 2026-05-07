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

info "Home Assistant - Plateforme domotique"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

# Installation dépendances
echo "=== Installation des dépendances ==="
case "$PKG_MANAGER" in
    apt)
        pkg_install python3 python3-dev python3-pip libffi-dev libssl-dev libjpeg-dev zlib1g-dev autoconf build-essential
        ;;
    dnf|yum)
        pkg_install python3 python3-devel gcc libffi-devel openssl-devel
        ;;
esac

# Installation Home Assistant
echo "=== Installation de Home Assistant ==="
pip3 install homeassistant

# Création répertoire de configuration
mkdir -p /opt/homeassistant
chmod 755 /opt/homeassistant

# Service systemd
cat > /etc/systemd/system/homeassistant.service <<EOF
[Unit]
Description=Home Assistant
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/homeassistant
ExecStart=/usr/local/bin/hass -c /opt/homeassistant
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable homeassistant
systemctl start homeassistant

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8123/tcp
fi

echo
echo "✅ Home Assistant en cours d'installation"
echo "URL: http://votre-serveur:8123"
echo "Configuration: /opt/homeassistant"
echo "Première mise en marche à la première visite"
