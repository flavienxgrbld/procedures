#!/usr/bin/env bash
# Installation de Plex Media Server depuis le dépôt officiel repo.plex.tv (clé v2).
#
# Variables facultatives :
#   MEDIA_DIR  dossier de médias à rendre lisible par Plex

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

info "Plex Media Server"

case "$PKG_MANAGER" in
    apt)
        pkg_update
        pkg_install curl gpg ca-certificates acl
        curl -fsSL https://downloads.plex.tv/plex-keys/PlexSign.v2.key | gpg --dearmor --yes -o /usr/share/keyrings/plexmediaserver.v2.gpg
        echo "deb [signed-by=/usr/share/keyrings/plexmediaserver.v2.gpg] https://repo.plex.tv/deb/ public main" \
            > /etc/apt/sources.list.d/plexmediaserver.list
        pkg_update
        ;;
    dnf|yum)
        rpm --import https://downloads.plex.tv/plex-keys/PlexSign.v2.key
        cat > /etc/yum.repos.d/plex.repo <<'EOF'
[PlexRepo]
name=PlexRepo
baseurl=https://repo.plex.tv/rpm/$basearch/
enabled=1
gpgkey=https://downloads.plex.tv/plex-keys/PlexSign.v2.key
gpgcheck=1
EOF
        pkg_install acl
        ;;
    *) error_exit "Dépôt Plex disponible pour apt et dnf/yum seulement" ;;
esac
pkg_install plexmediaserver
systemctl enable --now plexmediaserver
check_service_status plexmediaserver

if [ -n "${MEDIA_DIR:-}" ]; then
    [ -d "$MEDIA_DIR" ] || error_exit "Dossier de médias introuvable : $MEDIA_DIR"
    setfacl -R -m u:plex:rX "$MEDIA_DIR"
    setfacl -R -d -m u:plex:rX "$MEDIA_DIR"
fi
open_ports 32400/tcp

echo
echo "✅ Plex installé : http://$(primary_ip):32400/web"
echo "Première configuration depuis le réseau local (ou tunnel : ssh -L 8888:localhost:32400 <serveur>, puis http://localhost:8888/web)."
