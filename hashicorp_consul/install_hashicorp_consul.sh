#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Hashicorp Consul - Service mesh et service discovery"

CONSUL_VERSION="1.16.0"

echo "=== Installation de Hashicorp Consul ==="

# Création utilisateur
if ! id consul >/dev/null 2>&1; then
    useradd -r -s /bin/bash consul
fi

# Téléchargement
cd /tmp
wget "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip"
unzip "consul_${CONSUL_VERSION}_linux_amd64.zip"
mv consul /usr/local/bin/
rm "consul_${CONSUL_VERSION}_linux_amd64.zip"

# Configuration
mkdir -p /etc/consul.d
cat > /etc/consul.d/consul.hcl <<'EOF'
datacenter = "dc1"
server = true
bootstrap_expect = 3
ui = true
client_addr = "0.0.0.0"
bind_addr = "0.0.0.0"
EOF

# Service
cat > /etc/systemd/system/consul.service <<'EOF'
[Unit]
Description=Hashicorp Consul
After=network.target

[Service]
Type=simple
User=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable consul
systemctl start consul

echo
echo "✅ Hashicorp Consul installé avec succès"
echo "URL: http://votre-serveur:8500"
