#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Prometheus - Système de monitoring et de collecte de métriques"

PROMETHEUS_VERSION="latest"
PROMETHEUS_USER="prometheus"
PROMETHEUS_HOME="/opt/prometheus"
PROMETHEUS_DATA_DIR="/var/lib/prometheus"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

# Installation des dépendances
pkg_install wget curl

# Création de l'utilisateur Prometheus
if ! id "$PROMETHEUS_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/false -m -d "$PROMETHEUS_HOME" -c "Prometheus Service" "$PROMETHEUS_USER"
fi

# Installation de Prometheus
echo "=== Téléchargement de Prometheus ==="
cd /tmp
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) PROM_ARCH="amd64" ;;
    aarch64) PROM_ARCH="arm64" ;;
    armv7l) PROM_ARCH="armv7" ;;
    *) error_exit "Architecture non supportée" ;;
esac

if [ "$PROMETHEUS_VERSION" = "latest" ]; then
    PROMETHEUS_VERSION=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
fi

PROM_URL="https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-${PROM_ARCH}.tar.gz"
wget "$PROM_URL" -O prometheus.tar.gz
tar -xzf prometheus.tar.gz
rm prometheus.tar.gz

mv prometheus-${PROMETHEUS_VERSION}.linux-${PROM_ARCH} prometheus
mv prometheus/prometheus "$PROMETHEUS_HOME/"
mv prometheus/promtool "$PROMETHEUS_HOME/"

mkdir -p "$PROMETHEUS_DATA_DIR"
chown -R "$PROMETHEUS_USER:$PROMETHEUS_USER" "$PROMETHEUS_HOME"
chown -R "$PROMETHEUS_USER:$PROMETHEUS_USER" "$PROMETHEUS_DATA_DIR"

# Configuration Prometheus
echo "=== Configuration de Prometheus ==="
cat > "$PROMETHEUS_HOME/prometheus.yml" <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

chown "$PROMETHEUS_USER:$PROMETHEUS_USER" "$PROMETHEUS_HOME/prometheus.yml"

# Service systemd
cat > /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus
After=network.target

[Service]
Type=simple
User=$PROMETHEUS_USER
Group=$PROMETHEUS_USER
ExecStart=$PROMETHEUS_HOME/prometheus --config.file=$PROMETHEUS_HOME/prometheus.yml --storage.tsdb.path=$PROMETHEUS_DATA_DIR
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus

# Configuration firewall
if command -v ufw >/dev/null 2>&1; then
    ufw allow 9090/tcp
fi

echo
echo "✅ Prometheus installé avec succès"
echo "URL: http://votre-serveur:9090"
echo "Configuration: $PROMETHEUS_HOME/prometheus.yml"
