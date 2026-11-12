#!/usr/bin/env bash
# Installation de Netdata avec le script officiel kickstart.sh (paquets natifs, canal stable).
#
# Variables modifiables :
#   NETDATA_LOCAL  oui pour n'écouter que sur 127.0.0.1 (défaut : non, accès réservé au réseau local par ufw)

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

info "Netdata - Supervision en temps réel"

pkg_install curl ca-certificates
KS="$(mktemp --suffix=.sh)"
add_temp_file "$KS"
download_file https://get.netdata.cloud/kickstart.sh "$KS"
sh "$KS" --stable-channel --disable-telemetry --non-interactive

if [ "${NETDATA_LOCAL:-non}" = "oui" ]; then
    CONF=/etc/netdata/netdata.conf
    if [ -f "$CONF" ] && grep -q '^\[web\]' "$CONF"; then
        sed -i '/^\[web\]/,/^\[/ s/^\(\s*#\?\s*bind to\s*=\).*/    bind to = 127.0.0.1/' "$CONF"
        grep -q 'bind to = 127.0.0.1' "$CONF" || sed -i '/^\[web\]/a\    bind to = 127.0.0.1' "$CONF"
    else
        printf '[web]\n    bind to = 127.0.0.1\n' >> "$CONF"
    fi
    systemctl restart netdata
else
    LAN="$(ip -4 route show scope link 2>/dev/null | awk '!/docker|br-|veth/ {print $1; exit}')" || true
    if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active" && [ -n "$LAN" ]; then
        ufw allow from "$LAN" to any port 19999 proto tcp >/dev/null
        info "Port 19999 ouvert pour ${LAN} uniquement"
    fi
fi
check_service_status netdata

echo
echo "✅ Netdata installé : http://$(primary_ip):19999"
echo "Le tableau de bord n'a pas d'authentification : ne pas l'exposer hors du réseau d'administration."
