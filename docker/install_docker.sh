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

info "Docker - Plateforme de conteneurisation"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

echo "=== Installation de Docker ==="
case "$PKG_MANAGER" in
    apt)
        pkg_install apt-transport-https ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
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

systemctl enable docker
systemctl start docker

# Ajout utilisateur au groupe docker
read -p "Utilisateur à ajouter au groupe docker [ubuntu/admin]: " DOCKER_USER
DOCKER_USER=${DOCKER_USER:-ubuntu}
usermod -aG docker "$DOCKER_USER" 2>/dev/null || true

echo
echo "✅ Docker installé avec succès"
echo "Version: $(docker --version)"
echo "Docker Compose: $(docker compose version)"
echo "L'utilisateur doit se reconnecter pour que l'accès au groupe docker soit effectif"
