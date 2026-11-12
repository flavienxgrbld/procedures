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

info "Sentry - Monitoring d'erreurs et performance"

SENTRY_DIR="/opt/sentry"
SENTRY_USER="sentry"

echo "=== Installation de Sentry ==="
pkg_install python3 python3-dev python3-pip postgresql-client redis-server

# Création utilisateur
if ! id "$SENTRY_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -m -d "$SENTRY_DIR" -c "Sentry Service" "$SENTRY_USER"
fi

# Installation avec pip
pip3 install sentry-sdk

# Service Redis
systemctl enable redis-server
systemctl start redis-server

echo
echo "✅ Sentry en cours d'installation"
echo "Installation complète requiert Docker Compose"
echo "Documentation: https://develop.sentry.dev/self-hosted/"
