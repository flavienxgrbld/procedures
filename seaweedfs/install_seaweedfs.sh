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

info "Seaweed FS - Distributed object storage"

SEAWEEDFS_VERSION="3.57"

echo "=== Installation de SeaweedFS ==="

# Création utilisateur
if ! id seaweedfs >/dev/null 2>&1; then
    useradd -r -s /bin/bash seaweedfs
fi

# Téléchargement
cd /opt
wget "https://github.com/seaweedfs/seaweedfs/releases/download/${SEAWEEDFS_VERSION}/linux_amd64.tar.gz"
tar -xzf linux_amd64.tar.gz
rm linux_amd64.tar.gz
mv weed /usr/local/bin/

# Répertoires
mkdir -p /var/lib/seaweedfs
chown seaweedfs:seaweedfs /var/lib/seaweedfs

# Service master
cat > /etc/systemd/system/seaweedfs-master.service <<'EOF'
[Unit]
Description=SeaweedFS Master
After=network.target

[Service]
Type=simple
User=seaweedfs
ExecStart=/usr/local/bin/weed master -ip localhost
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable seaweedfs-master
systemctl start seaweedfs-master

if command -v ufw >/dev/null 2>&1; then
    ufw allow 9333/tcp
fi

echo
echo "✅ SeaweedFS en cours d'installation"
echo "Port Master: 9333"
echo "Documentation: https://github.com/seaweedfs/seaweedfs"
