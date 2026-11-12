#!/usr/bin/env bash
# Installation de Hyperledger Fabric (binaires, images Docker et fabric-samples)
# avec le script officiel install-fabric.sh, dans le dossier d'un utilisateur.
#
# Variables modifiables :
#   FABRIC_USER     utilisateur propriétaire (défaut : celui qui a lancé sudo)
#   FABRIC_VERSION  version de Fabric (défaut : celle choisie par install-fabric.sh)

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

info "Hyperledger Fabric - Blockchain permissionnée (réseau de test)"

FABRIC_USER="${FABRIC_USER:-${SUDO_USER:-}}"
[ -n "$FABRIC_USER" ] && [ "$FABRIC_USER" != "root" ] && id "$FABRIC_USER" >/dev/null 2>&1 \
    || error_exit "Lancer avec sudo depuis un compte utilisateur, ou définir FABRIC_USER (pas root)"
USER_HOME="$(getent passwd "$FABRIC_USER" | cut -d: -f6)"
FABRIC_DIR="${USER_HOME}/fabric"

pkg_update
pkg_install git curl jq
DOCKER_USER="$FABRIC_USER" ensure_docker
usermod -aG docker "$FABRIC_USER"

info "Téléchargement de Fabric dans ${FABRIC_DIR} (binaires, images, exemples)"
sudo -u "$FABRIC_USER" mkdir -p "$FABRIC_DIR"
sudo -u "$FABRIC_USER" curl -fsSL -o "${FABRIC_DIR}/install-fabric.sh" \
    https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh
chmod +x "${FABRIC_DIR}/install-fabric.sh"
args=(docker binary samples)
[ -n "${FABRIC_VERSION:-}" ] && args=(--fabric-version "$FABRIC_VERSION" "${args[@]}")
# sg docker : le groupe docker vient d'être ajouté, la session actuelle ne le connaît pas encore
sudo -u "$FABRIC_USER" sg docker -c "cd '${FABRIC_DIR}' && ./install-fabric.sh ${args[*]}"

PROFILE="${USER_HOME}/.bashrc"
LINE='export PATH=$HOME/fabric/fabric-samples/bin:$PATH'
grep -qxF "$LINE" "$PROFILE" 2>/dev/null || echo "$LINE" >> "$PROFILE"
chown "$FABRIC_USER:" "$PROFILE"

echo
echo "✅ Fabric installé dans ${FABRIC_DIR}/fabric-samples"
echo "Version : $("${FABRIC_DIR}/fabric-samples/bin/peer" version 2>/dev/null | awk '/Version:/{print $2; exit}')"
echo "Se reconnecter (groupe docker), puis :"
echo "  cd ~/fabric/fabric-samples/test-network && ./network.sh up createChannel -c canal1"
