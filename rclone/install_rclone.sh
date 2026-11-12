#!/usr/bin/env bash
# Installation de rclone (dernière version, script officiel) et de fuse3 pour « rclone mount ».
# La configuration des stockages se fait ensuite SANS sudo : rclone config.

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

info "rclone - Copie et synchronisation vers le cloud"

pkg_update
case "$PKG_MANAGER" in
    apt|dnf|yum|zypper) pkg_install curl unzip fuse3 ;;
    pacman) pkg_install curl unzip fuse3 ;;
esac

INSTALLER="$(mktemp)"
add_temp_file "$INSTALLER"
download_file https://rclone.org/install.sh "$INSTALLER"
# install.sh renvoie 3 quand la dernière version est déjà installée
bash "$INSTALLER" || [ $? -eq 3 ]

# Autoriser « --allow-other » pour les montages partagés entre utilisateurs
if [ -f /etc/fuse.conf ] && grep -q '^#user_allow_other' /etc/fuse.conf; then
    sed -i 's/^#user_allow_other/user_allow_other/' /etc/fuse.conf
fi

echo
echo "✅ $(rclone version | head -n1)"
echo "Configurer un stockage avec le compte qui fera les synchronisations (sans sudo) : rclone config"
echo "Chiffrer la configuration : rclone config, puis « s » (set configuration password)"
