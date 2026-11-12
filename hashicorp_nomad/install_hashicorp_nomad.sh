#!/usr/bin/env bash

set -euo pipefail

# Bibliothèque commune : copie du dépôt en priorité, téléchargement sinon.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/../install_common.sh"
if [ ! -f "$COMMON_SCRIPT" ]; then
    COMMON_SCRIPT="$(mktemp)"
    curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/procedures/main/install_common.sh" -o "$COMMON_SCRIPT"
fi
# shellcheck source=../install_common.sh
source "$COMMON_SCRIPT"

ensure_root
detect_os
detect_package_manager

info "Hashicorp Nomad - Orchestrateur de conteneurs et de microservices"

NOMAD_VERSION="1.6.0"

echo "=== Installation de Hashicorp Nomad ==="

# Création utilisateur
if ! id nomad >/dev/null 2>&1; then
    useradd -r -s /bin/bash nomad
fi

# Téléchargement
cd /tmp
wget "https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip"
unzip "nomad_${NOMAD_VERSION}_linux_amd64.zip"
mv nomad /usr/local/bin/
rm "nomad_${NOMAD_VERSION}_linux_amd64.zip"

# Configuration
mkdir -p /etc/nomad
cat > /etc/nomad/nomad.hcl <<'EOF'
server {
  enabled = true
  bootstrap_expect = 1
}

client {
  enabled = true
}

ui {
  enabled = true
}

datacenter = "dc1"
EOF

# Service
cat > /etc/systemd/system/nomad.service <<'EOF'
[Unit]
Description=Hashicorp Nomad
After=network.target

[Service]
Type=simple
User=nomad
ExecStart=/usr/local/bin/nomad agent -config=/etc/nomad/nomad.hcl
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nomad
systemctl start nomad

if command -v ufw >/dev/null 2>&1; then
    ufw allow 4646/tcp
fi

echo
echo "✅ Hashicorp Nomad installé avec succès"
echo "URL: http://votre-serveur:4646"
