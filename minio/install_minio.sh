#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "MinIO - Stockage d'objets compatibles S3"

MINIO_DIR="/opt/minio"
MINIO_USER="minio"
MINIO_DISK="/minio"

echo "=== Installation de MinIO ==="

# Création utilisateur
if ! id "$MINIO_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -m -d "$MINIO_DIR" -c "MinIO Service" "$MINIO_USER"
fi

# Téléchargement
cd /tmp
wget https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x minio
mv minio /usr/local/bin/

# Dossier de stockage
mkdir -p "$MINIO_DISK"
chown "$MINIO_USER:$MINIO_USER" "$MINIO_DISK"

# Service systemd
cat > /etc/systemd/system/minio.service <<'EOF'
[Unit]
Description=MinIO
After=network.target

[Service]
Type=simple
User=minio
ExecStart=/usr/local/bin/minio server /minio
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable minio
systemctl start minio

if command -v ufw >/dev/null 2>&1; then
    ufw allow 9000/tcp
    ufw allow 9001/tcp
fi

echo
echo "✅ MinIO installé avec succès"
echo "API: http://votre-serveur:9000"
echo "Console: http://votre-serveur:9001"
