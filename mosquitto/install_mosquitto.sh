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

info "Mosquitto - Broker MQTT pour IoT"

echo "=== Installation de Mosquitto ==="
pkg_install mosquitto mosquitto-clients

# Configuration
mkdir -p /etc/mosquitto/conf.d
cat > /etc/mosquitto/mosquitto.conf <<'EOF'
pid_file /var/run/mosquitto.pid

persistence true
persistence_location /var/lib/mosquitto/

log_dest file /var/log/mosquitto/mosquitto.log
log_dest stdout
log_dest topic

# Port par défaut
listener 1883
protocol mqtt

# WebSocket
listener 9001
protocol websockets
EOF

chown -R mosquitto:mosquitto /etc/mosquitto
chmod 644 /etc/mosquitto/mosquitto.conf

systemctl enable mosquitto
systemctl restart mosquitto

if command -v ufw >/dev/null 2>&1; then
    ufw allow 1883/tcp
    ufw allow 9001/tcp
fi

echo
echo "✅ Mosquitto installé avec succès"
echo "Port MQTT: 1883"
echo "Port WebSocket: 9001"
