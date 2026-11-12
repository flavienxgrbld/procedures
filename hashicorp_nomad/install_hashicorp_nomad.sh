#!/usr/bin/env bash
# Installation de Nomad (dépôt officiel HashiCorp) en nœud unique serveur + client,
# avec le pilote Docker.
#
# Variables modifiables :
#   NOMAD_DOCKER  oui (défaut) pour installer Docker et utiliser le pilote docker

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

info "Nomad - Orchestrateur de charges de travail"

NOMAD_DOCKER="${NOMAD_DOCKER:-oui}"

hashicorp_repo
pkg_install nomad
nomad version | head -n1

[ "$NOMAD_DOCKER" = "oui" ] && ensure_docker

mkdir -p /opt/nomad/data
CONF=/etc/nomad.d/nomad.hcl
backup_file "$CONF"
cat > "$CONF" <<EOF
# Généré par install_hashicorp_nomad.sh : nœud unique serveur + client
datacenter = "dc1"
data_dir   = "/opt/nomad/data"
bind_addr  = "0.0.0.0"

server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled = true
}

ui {
  enabled = true
}
EOF

nomad config validate /etc/nomad.d/
systemctl enable nomad
systemctl restart nomad
sleep 5
check_service_status nomad

open_ports 4646:4648/tcp 4648/udp

echo
echo "✅ Nomad installé (serveur + client)"
echo "Interface : http://$(primary_ip):4646/ui"
echo "Nœuds     : nomad node status"
