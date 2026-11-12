#!/usr/bin/env bash
# Installation d'Artica sur un Debian déjà installé, avec l'installateur officiel
# (méthode « Manual installation » du wiki Artica).
#
# ATTENTION : Artica transforme tout le système et ne se désinstalle pas.
# À n'utiliser que sur une machine (virtuelle) dédiée.
#
# Variables :
#   ARTICA_CONFIRM=oui        obligatoire pour lancer l'installation
#   ARTICA_INSTALLER_URL      URL de l'installateur (défaut : celle du wiki officiel)

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

info "Artica - Proxy, filtrage web et sécurité réseau"

ARTICA_INSTALLER_URL="${ARTICA_INSTALLER_URL:-http://articatech.net/download/v4/install-manuall.sh}"

[ "$OS_ID" = "debian" ] || error_exit "Artica ne s'installe que sur Debian (système détecté : ${OS_NAME})"
[ "$(uname -m)" = "x86_64" ] || error_exit "Artica n'existe qu'en 64 bits x86 (amd64)"

if [ "${ARTICA_CONFIRM:-}" != "oui" ]; then
    cat >&2 <<'EOF'
Artica modifie l'ensemble du système (environ 630 paquets, configuration réseau,
services) et ne peut pas être désinstallé. L'éditeur déconseille de l'installer
sur un serveur déjà en production.

Pour confirmer, relancer avec :
    sudo ARTICA_CONFIRM=oui bash install_artica.sh
EOF
    exit 1
fi

disk_gb=$(df -BG --output=avail / | tail -n1 | tr -dc '0-9')
if [ "${disk_gb:-0}" -lt 50 ]; then
    warn "Espace libre sur / : ${disk_gb} Go (50 Go conseillés par l'éditeur)"
fi

pkg_update
pkg_install wget ca-certificates

INSTALLER="$(mktemp --suffix=.sh)"
add_temp_file "$INSTALLER"
info "Téléchargement de l'installateur officiel : ${ARTICA_INSTALLER_URL}"
download_file "$ARTICA_INSTALLER_URL" "$INSTALLER"
head -n1 "$INSTALLER" | grep -q '^#!' || error_exit "Le fichier téléchargé n'est pas un script : vérifier ARTICA_INSTALLER_URL"
chmod 0755 "$INSTALLER"

info "Lancement de l'installateur Artica (répondre « No » pour le mode complet)"
"$INSTALLER"

echo
echo "✅ Installation d'Artica terminée."
echo "Redémarrer le serveur : sudo reboot"
echo "Puis ouvrir l'interface : https://$(hostname -I | awk '{print $1}'):9000"
