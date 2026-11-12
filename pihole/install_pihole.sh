#!/usr/bin/env bash
# Installation de Pi-hole avec l'installateur officiel (interactif), après avoir
# libéré le port 53 sur Ubuntu sans casser la résolution de noms.

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

info "Pi-hole - DNS filtrant pour tout le réseau"

if systemctl is-active --quiet systemd-resolved 2>/dev/null && ss -lnu | grep -q '127.0.0.53:53'; then
    info "Désactivation de l'écouteur DNS de systemd-resolved (port 53)"
    mkdir -p /etc/systemd/resolved.conf.d
    printf '[Resolve]\nDNSStubListener=no\n' > /etc/systemd/resolved.conf.d/no-stub.conf
    systemctl restart systemd-resolved
    [ -L /etc/resolv.conf ] && [ -e /run/systemd/resolve/resolv.conf ] && ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
fi

pkg_install curl
INSTALLER="/root/install-pihole.sh"
download_file https://install.pi-hole.net "$INSTALLER"
info "Installateur officiel enregistré dans ${INSTALLER} (relisible) : lancement"
bash "$INSTALLER"

open_ports 53/tcp 53/udp 80/tcp 443/tcp

echo
echo "✅ Pi-hole installé : http://$(primary_ip)/admin"
echo "Changer le mot de passe de l'interface : sudo pihole setpassword"
echo "Déclarer $(primary_ip) comme SEUL DNS distribué par le DHCP du réseau."
