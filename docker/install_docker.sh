#!/usr/bin/env bash

set -euo pipefail

COMMON_SCRIPT="/tmp/install_common.sh"
rm -f "$COMMON_SCRIPT"
curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/install-scripts/main/root/common/install_common.sh" -o "$COMMON_SCRIPT"
source "$COMMON_SCRIPT"

ensure_root
detect_os
detect_package_manager

info "Docker - Plateforme de conteneurisation"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

echo "=== Installation de Docker ==="
case "$PKG_MANAGER" in
    apt)
        pkg_install apt-transport-https ca-certificates curl gnupg lsb-release

        mkdir -p /usr/share/keyrings
        if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
            curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        fi

        if is_ubuntu; then
            DOCKER_REPO="ubuntu"
        else
            DOCKER_REPO="debian"
        fi

        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${DOCKER_REPO} $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        pkg_update
        pkg_install docker-ce docker-ce-cli containerd.io docker-compose-plugin
        ;;
    dnf|yum)
        pkg_install docker docker-compose
        ;;
    zypper)
        pkg_install docker docker-compose
        ;;
    pacman)
        pkg_install docker docker-compose
        ;;
esac

systemctl enable docker 2>/dev/null || true
systemctl start docker 2>/dev/null || true

DOCKER_USER="${SUDO_USER:-${USER:-ubuntu}}"
if [ -z "$DOCKER_USER" ] || [ "$DOCKER_USER" = "root" ]; then
    DOCKER_USER="ubuntu"
fi

if id "$DOCKER_USER" >/dev/null 2>&1; then
    usermod -aG docker "$DOCKER_USER" 2>/dev/null || true
else
    warn "L'utilisateur $DOCKER_USER n'existe pas sur le système, aucun ajout au groupe docker n'a été effectué"
fi

echo
echo "✅ Docker installé avec succès"
echo "Version: $(docker --version 2>/dev/null || echo 'non disponible')"
echo "Docker Compose: $(docker compose version 2>/dev/null || echo 'non disponible')"
echo "L'utilisateur doit se reconnecter pour que l'accès au groupe docker soit effectif"
