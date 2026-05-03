#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

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
