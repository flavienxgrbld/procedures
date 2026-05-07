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

info "Gitea - Service Git auto-hébergé simplifié"

GITEA_DIR="/var/lib/gitea"
GITEA_USER="git"

echo "=== Installation de Gitea ==="

# Création utilisateur
if ! id "$GITEA_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -m -d "$GITEA_DIR" -c "Gitea Service" "$GITEA_USER"
fi

# Dossiers
mkdir -p $GITEA_DIR
chown "$GITEA_USER:$GITEA_USER" $GITEA_DIR

# Installation Gitea
GITEA_VERSION="1.20.0"
cd /usr/local/bin
wget "https://github.com/go-gitea/gitea/releases/download/v${GITEA_VERSION}/gitea-${GITEA_VERSION}-linux-amd64" -O gitea
chmod +x gitea

# Service systemd
cat > /etc/systemd/system/gitea.service <<'EOF'
[Unit]
Description=Gitea
After=syslog.target network.target

[Service]
RestartPolicy=always
Type=simple
User=git
WorkingDirectory=/var/lib/gitea
ExecStart=/usr/local/bin/gitea web -c /etc/gitea/app.ini
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /etc/gitea
chown -R "$GITEA_USER:$GITEA_USER" /etc/gitea
chmod 770 /etc/gitea

systemctl daemon-reload
systemctl enable gitea
systemctl start gitea

if command -v ufw >/dev/null 2>&1; then
    ufw allow 3000/tcp
    ufw allow 22/tcp
fi

echo
echo "✅ Gitea installé avec succès"
echo "URL: http://votre-serveur:3000"
echo "SSH: votre-serveur:22"
