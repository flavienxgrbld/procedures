#!/usr/bin/env bash
# Installation d'Emby Server (dernier paquet .deb stable publié par l'éditeur sur GitHub).
#
# Variables modifiables :
#   EMBY_VERSION  version à installer (défaut : dernière version stable)
#   MEDIA_DIR     dossier de médias à rendre lisible par Emby (facultatif)

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
is_debian_family || error_exit "Ce script est prévu pour Debian ou Ubuntu"

info "Emby Server - Serveur multimédia"

case "$(dpkg --print-architecture)" in
    amd64) ARCH="amd64" ;;
    arm64) ARCH="arm64" ;;
    armhf) ARCH="armhf" ;;
    *) error_exit "Architecture non gérée : $(dpkg --print-architecture)" ;;
esac

pkg_update
pkg_install curl ca-certificates acl

EMBY_VERSION="${EMBY_VERSION:-$(github_latest_tag MediaBrowser/Emby.Releases)}"
[ -n "$EMBY_VERSION" ] || error_exit "Version introuvable : définir EMBY_VERSION (voir github.com/MediaBrowser/Emby.Releases/releases)"
DEB="emby-server-deb_${EMBY_VERSION}_${ARCH}.deb"
URL="https://github.com/MediaBrowser/Emby.Releases/releases/download/${EMBY_VERSION}/${DEB}"

info "Téléchargement de ${DEB}"
download_file "$URL" "/tmp/${DEB}"
add_temp_file "/tmp/${DEB}"
DEBIAN_FRONTEND=noninteractive apt-get install -y "/tmp/${DEB}"

systemctl enable --now emby-server
check_service_status emby-server

if [ -n "${MEDIA_DIR:-}" ]; then
    [ -d "$MEDIA_DIR" ] || error_exit "Dossier de médias introuvable : $MEDIA_DIR"
    info "Droits de lecture pour l'utilisateur emby sur ${MEDIA_DIR}"
    setfacl -R -m u:emby:rX "$MEDIA_DIR"
    setfacl -R -d -m u:emby:rX "$MEDIA_DIR"
fi

open_ports 8096/tcp 8920/tcp

echo
echo "✅ Emby Server ${EMBY_VERSION} installé"
echo "Assistant de configuration : http://$(hostname -I | awk '{print $1}'):8096"
