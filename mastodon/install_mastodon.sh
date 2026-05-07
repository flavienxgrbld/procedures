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

info "Mastodon - Réseau social décentralisé"

MASTODON_DIR="/opt/mastodon"
MASTODON_USER="mastodon"

echo "=== Installation de Mastodon ==="
echo "Mastodon est optimisé pour Docker"
echo ""

pkg_install docker.io docker-compose git

mkdir -p $MASTODON_DIR
cd $MASTODON_DIR

# Clone Mastodon
git clone https://github.com/mastodon/mastodon.git . || true

# Configuration
cp docker-compose.yml{.example,} 2>/dev/null || true
cp .env.production.sample .env.production 2>/dev/null || true

echo
echo "✅ Mastodon en cours d'installation"
echo "Configurez .env.production et lancez: docker-compose up -d"
