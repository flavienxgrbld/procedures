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

info "Vault - Gestion des secrets"

VAULT_VERSION="1.15.0"

echo "=== Installation de Hashicorp Vault ==="

# Création utilisateur
if ! id vault >/dev/null 2>&1; then
    useradd -r -s /bin/bash vault
fi

# Téléchargement
cd /tmp
wget "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip"
unzip "vault_${VAULT_VERSION}_linux_amd64.zip"
mv vault /usr/local/bin/
rm "vault_${VAULT_VERSION}_linux_amd64.zip"

setcap cap_ipc_lock=+ep /usr/local/bin/vault

# Configuration
mkdir -p /etc/vault
cat > /etc/vault/vault.hcl <<'EOF'
storage "file" {
  path = "/var/lib/vault"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable   = 1
}

ui = true
EOF

mkdir -p /var/lib/vault
chown vault:vault /var/lib/vault

# Service
cat > /etc/systemd/system/vault.service <<'EOF'
[Unit]
Description=Hashicorp Vault
After=network.target

[Service]
Type=simple
User=vault
ExecStart=/usr/local/bin/vault server -config=/etc/vault/vault.hcl
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vault
systemctl start vault

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8200/tcp
fi

echo
echo "✅ Hashicorp Vault installé avec succès"
echo "URL: http://votre-serveur:8200"
echo "Initialisez avec: vault operator init"
