#!/usr/bin/env bash

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

info "GitLab Runner - Runner CI/CD pour GitLab"

echo "=== Installation de GitLab Runner ==="
case "$PKG_MANAGER" in
    apt)
        curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | bash
        pkg_install gitlab-runner
        ;;
    dnf|yum)
        curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh | bash
        pkg_install gitlab-runner
        ;;
esac

# Service
systemctl enable gitlab-runner

echo
echo "✅ GitLab Runner installé"
echo "Pour enregistrer: gitlab-runner register"
echo "Vous aurez besoin:"
echo "  - GitLab URL"
echo "  - Registration token"
echo "  - Executor type (shell, docker, etc)"
