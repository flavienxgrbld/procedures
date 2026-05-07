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

info "Alertmanager - Gestionnaire d'alertes Prometheus"

ALERTMANAGER_VERSION="0.26.0"
ALERTMANAGER_USER="alertmanager"
ALERTMANAGER_HOME="/etc/alertmanager"

echo "=== Installation d'Alertmanager ==="

# Création utilisateur
if ! id "$ALERTMANAGER_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -m -c "Alertmanager Service" "$ALERTMANAGER_USER"
fi

# Téléchargement
cd /tmp
wget "https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz"
tar -xzf "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz"
cd "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64"

# Installation
cp alertmanager /usr/local/bin/
cp amtool /usr/local/bin/

mkdir -p "$ALERTMANAGER_HOME"
cp alertmanager.yml "$ALERTMANAGER_HOME/"
chown -R "$ALERTMANAGER_USER:$ALERTMANAGER_USER" "$ALERTMANAGER_HOME"

# Service systemd
cat > /etc/systemd/system/alertmanager.service <<'EOF'
[Unit]
Description=Alertmanager
After=network.target

[Service]
Type=simple
User=alertmanager
ExecStart=/usr/local/bin/alertmanager --config.file=/etc/alertmanager/alertmanager.yml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable alertmanager
systemctl start alertmanager

if command -v ufw >/dev/null 2>&1; then
    ufw allow 9093/tcp
fi

echo
echo "✅ Alertmanager installé avec succès"
echo "Port: 9093"
echo "Configuration: $ALERTMANAGER_HOME/alertmanager.yml"
