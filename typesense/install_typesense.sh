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

info "Typesense - Moteur de recherche rapide"

TYPESENSE_VERSION="0.25.0"

echo "=== Installation de Typesense ==="

# Création utilisateur
if ! id typesense >/dev/null 2>&1; then
    useradd -r -s /bin/bash typesense
fi

# Téléchargement
cd /tmp
wget "https://dl.typesense.org/releases/v${TYPESENSE_VERSION}/typesense-server-${TYPESENSE_VERSION}-linux-amd64.tar.gz"
tar -xzf "typesense-server-${TYPESENSE_VERSION}-linux-amd64.tar.gz"
mv typesense-server /usr/local/bin/
rm "typesense-server-${TYPESENSE_VERSION}-linux-amd64.tar.gz"

# Configuration
mkdir -p /var/lib/typesense
chown typesense:typesense /var/lib/typesense

# Service
cat > /etc/systemd/system/typesense.service <<'EOF'
[Unit]
Description=Typesense
After=network.target

[Service]
Type=simple
User=typesense
ExecStart=/usr/local/bin/typesense-server --data-dir /var/lib/typesense --listen-port 8108 --api-key=xyz
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable typesense
systemctl start typesense

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8108/tcp
fi

echo
echo "✅ Typesense installé avec succès"
echo "API URL: http://votre-serveur:8108"
echo "Changez la clé API!"
