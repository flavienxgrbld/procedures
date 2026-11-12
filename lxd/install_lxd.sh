#!/usr/bin/env bash
# Conteneurs système et machines virtuelles :
#   Ubuntu : LXD (snap officiel de Canonical)
#   Debian : Incus (successeur communautaire de LXD, paquet Debian)
#
# Variables modifiables :
#   LXD_USER  utilisateur ajouté au groupe d'administration (défaut : celui qui a lancé sudo)

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

LXD_USER="${LXD_USER:-${SUDO_USER:-}}"

if is_ubuntu; then
    info "LXD (snap) - Conteneurs système et machines virtuelles"
    pkg_install snapd
    snap list lxd >/dev/null 2>&1 || snap install lxd
    snap refresh lxd >/dev/null 2>&1 || true
    lxd waitready --timeout=120
    if ! lxc storage list --format csv 2>/dev/null | grep -q .; then
        lxd init --minimal
    fi
    GROUP="lxd"; CMD="lxc"; IMAGE="ubuntu:24.04"
elif [ "$OS_ID" = "debian" ]; then
    info "Incus - Conteneurs système et machines virtuelles"
    if [ "${OS_VERSION_ID%%.*}" = "12" ]; then
        info "Debian 12 : Incus vient du dépôt bookworm-backports"
        echo "deb http://deb.debian.org/debian bookworm-backports main" > /etc/apt/sources.list.d/backports.list
        pkg_update
        DEBIAN_FRONTEND=noninteractive apt-get install -y -t bookworm-backports incus
    else
        pkg_update
        pkg_install incus
    fi
    systemctl enable --now incus
    if ! incus storage list --format csv 2>/dev/null | grep -q .; then
        incus admin init --minimal
    fi
    GROUP="incus-admin"; CMD="incus"; IMAGE="images:debian/12"
else
    error_exit "Ce script gère Ubuntu (LXD) et Debian (Incus)"
fi

if [ -n "$LXD_USER" ] && [ "$LXD_USER" != "root" ] && id "$LXD_USER" >/dev/null 2>&1; then
    usermod -aG "$GROUP" "$LXD_USER"
    info "${LXD_USER} ajouté au groupe ${GROUP} (reconnexion nécessaire)"
fi

echo
echo "✅ ${CMD} prêt (initialisation minimale : stockage « dir » et pont réseau par défaut)"
echo "Premier conteneur : ${CMD} launch ${IMAGE} web1 && ${CMD} list"
