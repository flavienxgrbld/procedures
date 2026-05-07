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

info "Gitpod - Environnement de développement en ligne"

echo "=== Installation de Gitpod ==="
pkg_install docker.io kubernetes-client

echo "⚠️  Gitpod nécessite:"
echo "  - Docker ou Kubernetes"
echo "  - Configuration avancée"
echo "  - Domaine avec DNS"
echo ""
echo "Installation déploiement personnalisé:"
echo "https://www.gitpod.io/docs/self-hosted/"
echo ""
echo "Pour développement local: utiliser version SaaS"
