#!/usr/bin/env bash
# Installation d'Uptime Kuma 2 (image officielle) avec Docker Compose.

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

info "Uptime Kuma - Surveillance de disponibilité"

APP_DIR="/opt/uptime-kuma"
ensure_docker
mkdir -p "${APP_DIR}/data"
cat > "${APP_DIR}/compose.yaml" <<'EOF'
services:
  uptime-kuma:
    image: louislam/uptime-kuma:2
    container_name: uptime-kuma
    restart: unless-stopped
    ports:
      - "3001:3001"
    volumes:
      - ./data:/app/data
EOF
compose_up "$APP_DIR"
open_ports 3001/tcp

echo
echo "✅ Uptime Kuma démarré : http://$(primary_ip):3001 -> créer le compte administrateur sans attendre"
