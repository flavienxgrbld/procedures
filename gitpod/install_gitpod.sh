#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

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
