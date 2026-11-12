#!/usr/bin/env bash
# Installation de Consul (dépôt officiel HashiCorp) en serveur unique avec interface web.
#
# Variables modifiables :
#   CONSUL_BIND_ADDR   adresse d'écoute du cluster (défaut : adresse principale de la machine)
#   CONSUL_DATACENTER  nom du datacenter (défaut : dc1)

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

info "Consul - Découverte de services et configuration distribuée"

CONSUL_BIND_ADDR="${CONSUL_BIND_ADDR:-$(primary_ip)}"
CONSUL_DATACENTER="${CONSUL_DATACENTER:-dc1}"
[ -n "$CONSUL_BIND_ADDR" ] || error_exit "Adresse introuvable : définir CONSUL_BIND_ADDR"

hashicorp_repo
pkg_install consul
consul version | head -n1

CONF=/etc/consul.d/consul.hcl
backup_file "$CONF"
if [ -f "$CONF" ] && grep -q '^encrypt' "$CONF"; then
    ENCRYPT_KEY="$(sed -nE 's/^encrypt *= *"([^"]+)".*/\1/p' "$CONF")"
else
    ENCRYPT_KEY="$(consul keygen)"
fi
cat > "$CONF" <<EOF
# Généré par install_hashicorp_consul.sh : serveur unique
datacenter       = "${CONSUL_DATACENTER}"
data_dir         = "/opt/consul"
server           = true
bootstrap_expect = 1
bind_addr        = "${CONSUL_BIND_ADDR}"
client_addr      = "0.0.0.0"
encrypt          = "${ENCRYPT_KEY}"

ui_config {
  enabled = true
}
EOF
chown consul:consul "$CONF"
chmod 640 "$CONF"

consul validate /etc/consul.d/
systemctl enable consul
systemctl restart consul
sleep 3
check_service_status consul

open_ports 8500/tcp 8600/udp 8600/tcp 8300:8302/tcp 8301:8302/udp

echo
echo "✅ Consul installé (serveur unique, datacenter ${CONSUL_DATACENTER})"
echo "Interface : http://${CONSUL_BIND_ADDR}:8500/ui"
echo "Membres   : consul members"
echo "Clé de chiffrement du cluster (à reprendre sur les autres nœuds) : dans ${CONF}"
