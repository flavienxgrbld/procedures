#!/usr/bin/env bash

set -euo pipefail

COMMON_SCRIPT="/tmp/install_common.sh"
if [ ! -f "$COMMON_SCRIPT" ]; then
    curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/install-scripts/main/root/common/install_common.sh" -o "$COMMON_SCRIPT"
fi
source "$COMMON_SCRIPT"

ensure_root
detect_os
detect_package_manager

info "Seafile - Plateforme de partage de fichiers"

SEAFILE_VERSION="11.0"
SEAFILE_USER="seafile"
SEAFILE_HOME="/opt/seafile"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

# Installation dépendances
pkg_install python3 python3-dev python3-pip libmysqlclient-dev libssl-dev libjpeg-dev zlib1g-dev

# Installation base de données
install_database

# Création utilisateur
if ! id "$SEAFILE_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -m -d "$SEAFILE_HOME" -c "Seafile Service" "$SEAFILE_USER"
fi

# Installation Seafile
echo "=== Installation de Seafile ==="
cd /opt
wget "https://github.com/haiwen/seafile-rpi/releases/download/v${SEAFILE_VERSION}-server/seafile-server_${SEAFILE_VERSION}_x86-64.tar.gz"
tar -xzf "seafile-server_${SEAFILE_VERSION}_x86-64.tar.gz"
rm "seafile-server_${SEAFILE_VERSION}_x86-64.tar.gz"

mv seafile-server-${SEAFILE_VERSION} seafile
chown -R "$SEAFILE_USER:$SEAFILE_USER" "$SEAFILE_HOME"

echo
echo "✅ Seafile installé"
echo "Suivez le guide de configuration en ligne"
echo "Répertoire: $SEAFILE_HOME"
