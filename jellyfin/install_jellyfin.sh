#!/usr/bin/env bash
# Installation de Jellyfin avec le dépôt officiel (script install-debuntu.sh de l'éditeur).
#
# Variables facultatives :
#   MEDIA_DIR  dossier de médias à rendre lisible par Jellyfin
#   JELLYFIN_VAAPI=oui  ajoute jellyfin au groupe render (transcodage matériel Intel/AMD)

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

info "Jellyfin - Serveur multimédia libre"

case "$PKG_MANAGER" in
    apt) ;;
    *) error_exit "Dépôt officiel pour Debian et Ubuntu uniquement (Fedora : RPM Fusion ; Arch : paquet jellyfin-server)" ;;
esac

pkg_update
pkg_install curl ca-certificates acl

INSTALLER="$(mktemp)"
add_temp_file "$INSTALLER"
download_file https://repo.jellyfin.org/install-debuntu.sh "$INSTALLER"
info "Exécution du script officiel de l'éditeur (dépôt + paquets)"
# Le script officiel demande une confirmation : on la lui fournit
bash "$INSTALLER" < <(yes)

systemctl enable --now jellyfin
check_service_status jellyfin

if [ -n "${MEDIA_DIR:-}" ]; then
    [ -d "$MEDIA_DIR" ] || error_exit "Dossier de médias introuvable : $MEDIA_DIR"
    setfacl -R -m u:jellyfin:rX "$MEDIA_DIR"
    setfacl -R -d -m u:jellyfin:rX "$MEDIA_DIR"
    info "Lecture autorisée pour jellyfin sur ${MEDIA_DIR}"
fi
if [ "${JELLYFIN_VAAPI:-non}" = "oui" ] && getent group render >/dev/null; then
    usermod -aG render jellyfin
    systemctl restart jellyfin
fi

open_ports 8096/tcp 7359/udp

echo
echo "✅ Jellyfin installé : http://$(primary_ip):8096 (créer le compte administrateur sans attendre)"
