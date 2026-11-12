#!/usr/bin/env bash
# Installation de FOG Project avec l'installateur officiel (bin/installfog.sh),
# depuis la branche stable du dépôt GitHub. L'installateur reste interactif.
#
# Variables modifiables :
#   FOG_BRANCH     branche ou version (défaut : master, la branche stable)
#   FOG_BASE_DIR   dossier des sources (défaut : /opt/fogproject)

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

info "FOG Project - Clonage et déploiement de postes par le réseau"

FOG_BRANCH="${FOG_BRANCH:-master}"
FOG_BASE_DIR="${FOG_BASE_DIR:-/opt/fogproject}"

case "$PKG_MANAGER" in
    apt|dnf|yum) ;;
    *) error_exit "FOG Project prend en charge Debian, Ubuntu et la famille Red Hat (gestionnaire détecté : $PKG_MANAGER)" ;;
esac

# FOG a besoin d'une adresse IP fixe : on prévient si l'interface est en DHCP
IFACE="$(ip -4 route show default | awk '{print $5; exit}')"
if ip -4 addr show dev "$IFACE" 2>/dev/null | grep -q dynamic; then
    warn "L'interface ${IFACE} reçoit son adresse par DHCP : configurer une IP fixe avant d'installer FOG (étape 1 du README)."
fi

pkg_update
pkg_install git ca-certificates curl tar gzip

if [ -d "${FOG_BASE_DIR}/.git" ]; then
    info "Mise à jour des sources dans ${FOG_BASE_DIR}"
    git -C "$FOG_BASE_DIR" fetch --depth 1 origin "$FOG_BRANCH"
    git -C "$FOG_BASE_DIR" checkout -q FETCH_HEAD
else
    info "Récupération de FOG (${FOG_BRANCH})"
    git clone --depth 1 --branch "$FOG_BRANCH" https://github.com/FOGProject/fogproject.git "$FOG_BASE_DIR"
fi
[ -f "${FOG_BASE_DIR}/bin/installfog.sh" ] || error_exit "bin/installfog.sh introuvable dans ${FOG_BASE_DIR}"

# Interface web, TFTP, FTP, NFS (DHCP seulement si FOG le fournit : port ouvert par l'utilisateur)
open_ports 80/tcp 443/tcp 69/udp 21/tcp 2049/tcp 2049/udp 111/tcp 111/udp

info "Lancement de l'installateur officiel (questions : voir le tableau de l'étape 3 du README)"
cd "${FOG_BASE_DIR}/bin"
bash ./installfog.sh

echo
echo "✅ Installation de FOG terminée"
echo "Interface : http://$(hostname -I | awk '{print $1}')/fog/management"
echo "Compte par défaut : fog / password (à changer immédiatement)"
echo "Si FOG fournit le DHCP : ouvrir aussi le port 67/udp."
