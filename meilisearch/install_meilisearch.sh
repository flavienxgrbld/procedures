#!/usr/bin/env bash

set -euo pipefail

# Bibliothèque commune : copie du dépôt en priorité, téléchargement sinon.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/../install_common.sh"
if [ ! -f "$COMMON_SCRIPT" ]; then
    COMMON_SCRIPT="$(mktemp)"
    curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/install-scripts/main/root/common/install_common.sh" -o "$COMMON_SCRIPT"
fi
# shellcheck source=../install_common.sh
source "$COMMON_SCRIPT"

ensure_root
detect_os
detect_package_manager

info "Meili Search - Moteur de recherche performant"

echo "=== Installation de Meilisearch ==="
case "$PKG_MANAGER" in
    apt)
        curl -L https://install.meilisearch.com | sh
        ;;
    dnf|yum)
        curl -L https://install.meilisearch.com | sh
        ;;
esac

# Service
mkdir -p /var/lib/meilisearch
chown nobody:nogroup /var/lib/meilisearch

cat > /etc/systemd/system/meilisearch.service <<'EOF'
[Unit]
Description=Meilisearch
After=syslog.target network.target

[Service]
Type=simple
User=nobody
ExecStart=/usr/bin/meilisearch --db-path /var/lib/meilisearch
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable meilisearch
systemctl start meilisearch

if command -v ufw >/dev/null 2>&1; then
    ufw allow 7700/tcp
fi

echo
echo "✅ Meilisearch en cours d'installation"
echo "URL API: http://votre-serveur:7700"
