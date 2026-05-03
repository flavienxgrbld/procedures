#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Loki - Système de logs centralisé"

LOKI_VERSION="latest"
LOKI_USER="loki"
LOKI_HOME="/opt/loki"
LOKI_DATA_DIR="/var/lib/loki"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

pkg_install wget curl

if ! id "$LOKI_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/false -m -d "$LOKI_HOME" -c "Loki Service" "$LOKI_USER"
fi

echo "=== Installation de Loki ==="
cd /tmp
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) LOKI_ARCH="amd64" ;;
    aarch64) LOKI_ARCH="arm64" ;;
    armv7l) LOKI_ARCH="armv7" ;;
    *) error_exit "Architecture non supportée" ;;
esac

if [ "$LOKI_VERSION" = "latest" ]; then
    LOKI_VERSION=$(curl -s https://api.github.com/repos/grafana/loki/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
fi

wget "https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/loki-linux-${LOKI_ARCH}.zip" -O loki.zip
unzip loki.zip
chmod +x loki-linux-${LOKI_ARCH}
mv loki-linux-${LOKI_ARCH} "$LOKI_HOME/loki"
rm loki.zip

mkdir -p "$LOKI_DATA_DIR"
chown -R "$LOKI_USER:$LOKI_USER" "$LOKI_HOME"
chown -R "$LOKI_USER:$LOKI_USER" "$LOKI_DATA_DIR"

# Configuration Loki
cat > "$LOKI_HOME/loki-config.yml" <<'EOF'
auth_enabled: false

ingester:
  chunk_idle_period: 3m
  chunk_retain_period: 1m

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

schema_config:
  configs:
  - from: 2020-10-24
    store: boltdb-shipper
    object_store: filesystem
    schema:
      prefix: index_
      period: 24h
    index:
      prefix: index_
      period: 24h

server:
  http_listen_port: 3100
  log_level: info

storage_config:
  boltdb_shipper:
    active_index_directory: /var/lib/loki/boltdb-shipper-active
    cache_location: /var/lib/loki/boltdb-shipper-cache
    shared_store: filesystem
  filesystem:
    directory: /var/lib/loki/chunks
EOF

chown "$LOKI_USER:$LOKI_USER" "$LOKI_HOME/loki-config.yml"

# Service systemd
cat > /etc/systemd/system/loki.service <<EOF
[Unit]
Description=Loki
After=network.target

[Service]
Type=simple
User=$LOKI_USER
Group=$LOKI_USER
ExecStart=$LOKI_HOME/loki -config.file=$LOKI_HOME/loki-config.yml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable loki
systemctl start loki

if command -v ufw >/dev/null 2>&1; then
    ufw allow 3100/tcp
fi

echo
echo "✅ Loki installé avec succès"
echo "Port: 3100"
