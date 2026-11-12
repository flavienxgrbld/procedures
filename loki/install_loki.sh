#!/usr/bin/env bash
# Installation de Loki (dépôt officiel Grafana) en serveur unique, avec la
# configuration fournie par le paquet (stockage TSDB sur disque local).
#
# Variables modifiables :
#   LOKI_ALLOW_FROM  réseau autorisé à envoyer des journaux sur 3100 (défaut : réseau local détecté)

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

info "Loki - Centralisation des journaux"

grafana_repo
pkg_install loki
systemctl enable loki
systemctl restart loki
sleep 3
check_service_status loki

info "Attente de l'API Loki"
for _ in $(seq 1 30); do curl -fsS http://127.0.0.1:3100/ready >/dev/null 2>&1 && break; sleep 2; done

LAN="$(ip -4 route show scope link 2>/dev/null | awk '!/docker|br-|veth/ {print $1; exit}')" || true
LOKI_ALLOW_FROM="${LOKI_ALLOW_FROM:-$LAN}"
if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active" && [ -n "$LOKI_ALLOW_FROM" ]; then
    ufw allow from "$LOKI_ALLOW_FROM" to any port 3100 proto tcp >/dev/null
    info "Port 3100 ouvert pour ${LOKI_ALLOW_FROM} uniquement"
fi

echo
echo "✅ Loki $(loki --version 2>/dev/null | awk 'NR==1{print $3}') installé : http://$(primary_ip):3100"
echo "Configuration : /etc/loki/config.yml — test : curl http://localhost:3100/ready"
echo "Agents : installer Grafana Alloy sur les machines à surveiller (étape 4 du README)."
