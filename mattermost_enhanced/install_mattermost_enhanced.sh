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

info "Mattermost - Plateforme de collaboration d'entreprise"

MATTERMOST_DIR="/opt/mattermost"
MATTERMOST_USER="mattermost"
MATTERMOST_DB="mattermost"

echo "=== Installation de Mattermost ==="

# Installation base de données
install_database

# Création utilisateur
if ! id "$MATTERMOST_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -m -d "$MATTERMOST_DIR" -c "Mattermost Service" "$MATTERMOST_USER"
fi

# Téléchargement Mattermost
cd /opt
MATTERMOST_VERSION="7.8.0"
wget "https://releases.mattermost.com/mattermost-server/v${MATTERMOST_VERSION}/mattermost-v${MATTERMOST_VERSION}-linux-amd64.tar.gz"
tar -xzf "mattermost-v${MATTERMOST_VERSION}-linux-amd64.tar.gz"
rm "mattermost-v${MATTERMOST_VERSION}-linux-amd64.tar.gz"

mkdir -p $MATTERMOST_DIR/data
chown -R "$MATTERMOST_USER:$MATTERMOST_USER" $MATTERMOST_DIR

# Configuration DB
read -sp "Mot de passe Mattermost DB: " DB_PASS
echo
mysql -e "CREATE DATABASE $MATTERMOST_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER 'mattermost'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON $MATTERMOST_DB.* TO 'mattermost'@'localhost';"

# Service
cat > /etc/systemd/system/mattermost.service <<'EOF'
[Unit]
Description=Mattermost
After=network.target

[Service]
Type=simple
User=mattermost
ExecStart=/opt/mattermost/bin/mattermost
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mattermost
systemctl start mattermost

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8065/tcp
fi

echo
echo "✅ Mattermost en cours d'installation"
echo "URL: http://votre-serveur:8065"
