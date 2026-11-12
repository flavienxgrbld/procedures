#!/usr/bin/env bash
# Installation de Syncthing 2 (dépôt officiel, canal stable-v2) pour un utilisateur.
#
# Variables modifiables :
#   SYNC_USER  utilisateur dont Syncthing synchronise les dossiers (défaut : celui qui a lancé sudo)

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

info "Syncthing - Synchronisation de pair à pair"

SYNC_USER="${SYNC_USER:-${SUDO_USER:-}}"
[ -n "$SYNC_USER" ] && [ "$SYNC_USER" != "root" ] && id "$SYNC_USER" >/dev/null 2>&1 \
    || error_exit "Lancer avec sudo depuis le compte à synchroniser, ou définir SYNC_USER (pas root)"

pkg_update
pkg_install curl ca-certificates
install -m 0755 -d /etc/apt/keyrings
download_file https://syncthing.net/release-key.gpg /etc/apt/keyrings/syncthing-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable-v2" \
    > /etc/apt/sources.list.d/syncthing.list
pkg_update
pkg_install syncthing

systemctl enable "syncthing@${SYNC_USER}"
systemctl restart "syncthing@${SYNC_USER}"
check_service_status "syncthing@${SYNC_USER}"
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    ufw allow syncthing >/dev/null
fi

echo
echo "✅ Syncthing actif pour ${SYNC_USER} (interface sur 127.0.0.1:8384)"
echo "Depuis son poste : ssh -L 8384:localhost:8384 ${SYNC_USER}@$(primary_ip), puis http://localhost:8384"
echo "Définir immédiatement un identifiant et un mot de passe pour l'interface."
