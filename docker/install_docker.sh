#!/usr/bin/env bash
# Installation de Docker Engine et du plugin Compose depuis le dépôt officiel Docker.
#
# Variables modifiables :
#   DOCKER_USER  utilisateur à ajouter au groupe docker (défaut : celui qui a lancé sudo)

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

info "Docker - Plateforme de conteneurs"

DOCKER_PKGS=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)

case "$PKG_MANAGER" in
    apt)
        # Paquets non officiels qui entrent en conflit avec ceux de Docker
        for p in docker.io docker-doc docker-compose podman-docker containerd runc; do
            if dpkg -s "$p" >/dev/null 2>&1; then
                warn "Suppression du paquet en conflit : $p"
                apt-get remove -y "$p"
            fi
        done
        pkg_update
        pkg_install ca-certificates curl

        # shellcheck disable=SC1091
        . /etc/os-release
        if is_ubuntu || [[ "${ID_LIKE:-}" == *ubuntu* ]]; then
            DOCKER_DISTRO="ubuntu"; CODENAME="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
        else
            DOCKER_DISTRO="debian"; CODENAME="${VERSION_CODENAME}"
        fi

        install -m 0755 -d /etc/apt/keyrings
        download_file "https://download.docker.com/linux/${DOCKER_DISTRO}/gpg" /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${DOCKER_DISTRO} ${CODENAME} stable" \
            > /etc/apt/sources.list.d/docker.list
        pkg_update
        pkg_install "${DOCKER_PKGS[@]}"
        ;;
    dnf)
        if [ "$OS_ID" = "fedora" ]; then REPO_DISTRO="fedora"; else REPO_DISTRO="rhel"; fi
        pkg_install dnf-plugins-core
        dnf config-manager --add-repo "https://download.docker.com/linux/${REPO_DISTRO}/docker-ce.repo" \
            || dnf config-manager addrepo --from-repofile="https://download.docker.com/linux/${REPO_DISTRO}/docker-ce.repo"
        pkg_install "${DOCKER_PKGS[@]}"
        ;;
    zypper)
        pkg_install docker docker-compose
        ;;
    pacman)
        pkg_install docker docker-compose docker-buildx
        ;;
    *)
        error_exit "Gestionnaire de paquets non géré : $PKG_MANAGER"
        ;;
esac

systemctl enable --now docker
check_service_status docker

DOCKER_USER="${DOCKER_USER:-${SUDO_USER:-}}"
if [ -n "$DOCKER_USER" ] && [ "$DOCKER_USER" != "root" ] && id "$DOCKER_USER" >/dev/null 2>&1; then
    usermod -aG docker "$DOCKER_USER"
    info "Utilisateur ${DOCKER_USER} ajouté au groupe docker (reconnexion nécessaire)"
else
    info "Aucun utilisateur ajouté au groupe docker (lancer avec sudo ou définir DOCKER_USER)"
fi

info "Test : conteneur hello-world"
docker run --rm hello-world >/dev/null && info "Docker fonctionne"

echo
echo "✅ $(docker --version)"
echo "✅ $(docker compose version)"
