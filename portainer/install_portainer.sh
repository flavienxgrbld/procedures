#!/usr/bin/env bash
# Installation de Portainer Community Edition (version LTS) dans un conteneur.
#
# Variables modifiables :
#   PORTAINER_EDGE  oui pour publier aussi le port 8000 (agents Edge) (défaut : non)

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

info "Portainer CE - Administration de Docker"

ensure_docker
docker volume create portainer_data >/dev/null
if docker ps -a --format '{{.Names}}' | grep -qx portainer; then
    info "Mise à jour du conteneur existant"
    docker pull portainer/portainer-ce:lts >/dev/null
    docker rm -f portainer >/dev/null
fi
ports=(-p 9443:9443)
[ "${PORTAINER_EDGE:-non}" = "oui" ] && ports+=(-p 8000:8000)
docker run -d "${ports[@]}" --name portainer --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:lts >/dev/null
open_ports 9443/tcp

echo
echo "✅ Portainer démarré : https://$(primary_ip):9443"
echo "Créer le compte administrateur DANS LES 5 MINUTES (sinon : sudo docker restart portainer)."
