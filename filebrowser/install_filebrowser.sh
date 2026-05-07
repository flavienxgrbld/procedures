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

info "Filebrowser - Gestionnaire de fichiers web"

FILEBROWSER_VERSION="2.26.0"

echo "=== Installation de Filebrowser ==="
cd /tmp
wget "https://github.com/filebrowser/filebrowser/releases/download/v${FILEBROWSER_VERSION}/linux-amd64-filebrowser.tar.gz"
tar -xzf linux-amd64-filebrowser.tar.gz
mv filebrowser /usr/local/bin/
rm linux-amd64-filebrowser.tar.gz

# Configuration
mkdir -p /etc/filebrowser
cat > /etc/systemd/system/filebrowser.service <<'EOF'
[Unit]
Description=Filebrowser
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/filebrowser -c /etc/filebrowser/filebrowser.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable filebrowser
systemctl start filebrowser

if command -v ufw >/dev/null 2>&1; then
    ufw allow 80/tcp
fi

echo
echo "✅ Filebrowser installé avec succès"
echo "URL: http://votre-serveur"
echo "Utilisateur par défaut: admin / admin"
