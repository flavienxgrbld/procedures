#!/usr/bin/env bash
# Installation de Kodi (centre multimédia, application graphique) :
# PPA officiel sur Ubuntu, dépôts Debian, RPM Fusion sur Fedora, dépôts Arch.

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

info "Kodi - Centre multimédia"

if ! systemctl get-default 2>/dev/null | grep -q graphical; then
    warn "Aucune interface graphique détectée : Kodi est une application de bureau (voir Jellyfin/Emby/Plex pour un serveur)"
fi

case "$PKG_MANAGER" in
    apt)
        pkg_update
        if is_ubuntu; then
            info "Ubuntu : PPA officiel team-xbmc (dernière version)"
            pkg_install software-properties-common
            add-apt-repository -y ppa:team-xbmc/ppa
            pkg_update
        else
            info "Debian : paquet des dépôts officiels"
        fi
        pkg_install kodi
        ;;
    dnf)
        if [ "$OS_ID" = "fedora" ]; then
            pkg_install "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
        else
            pkg_install epel-release || true
            pkg_install "https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm"
        fi
        pkg_install kodi
        ;;
    pacman) pkg_install kodi ;;
    zypper) error_exit "openSUSE : activer le dépôt Packman, puis « zypper install kodi »" ;;
esac

echo
echo "✅ Kodi installé : le lancer depuis le menu des applications, ou avec la commande « kodi »"
