#!/usr/bin/env bash
# Installation de dnsmasq comme serveur DNS (cache + noms locaux) du réseau,
# avec DHCP en option.
#
# Variables modifiables (valeurs détectées par défaut) :
#   DNS_INTERFACE  interface d'écoute (défaut : celle de la route par défaut)
#   DNS_IP         adresse IP du serveur sur cette interface
#   DNS_DOMAIN     domaine local (défaut : lab.local)
#   DNS_UPSTREAM   serveurs DNS en amont, séparés par des espaces (défaut : "1.1.1.1 9.9.9.9")
#   DHCP_RANGE     ex. "192.168.1.100,192.168.1.200,12h" ; vide = pas de DHCP (défaut)
#   DHCP_ROUTER    passerelle annoncée en DHCP (défaut : passerelle actuelle)

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

info "Dnsmasq - Serveur DNS/DHCP léger"

DNS_INTERFACE="${DNS_INTERFACE:-$(ip -4 route show default | awk '{print $5; exit}')}"
[ -n "$DNS_INTERFACE" ] || error_exit "Interface introuvable : définir DNS_INTERFACE"
DNS_IP="${DNS_IP:-$(ip -4 -o addr show dev "$DNS_INTERFACE" | awk '{split($4,a,"/"); print a[1]; exit}')}"
[ -n "$DNS_IP" ] || error_exit "Adresse IP introuvable sur ${DNS_INTERFACE} : définir DNS_IP"
DNS_DOMAIN="${DNS_DOMAIN:-lab.local}"
DNS_UPSTREAM="${DNS_UPSTREAM:-1.1.1.1 9.9.9.9}"
DHCP_RANGE="${DHCP_RANGE:-}"
DHCP_ROUTER="${DHCP_ROUTER:-$(ip -4 route show default | awk '{print $3; exit}')}"

info "Interface ${DNS_INTERFACE}, adresse ${DNS_IP}, domaine ${DNS_DOMAIN}"

# systemd-resolved (Ubuntu) occupe le port 53 : on coupe son écouteur local
# AVANT d'installer dnsmasq, sinon le paquet échoue au démarrage du service.
if systemctl is-active --quiet systemd-resolved 2>/dev/null && ss -lnu | grep -q '127.0.0.53:53'; then
    info "Désactivation de l'écouteur DNS de systemd-resolved"
    mkdir -p /etc/systemd/resolved.conf.d
    printf '[Resolve]\nDNSStubListener=no\n' > /etc/systemd/resolved.conf.d/no-stub.conf
    systemctl restart systemd-resolved
    # /etc/resolv.conf pointait vers 127.0.0.53, qui ne répond plus
    if [ -L /etc/resolv.conf ] && [ -e /run/systemd/resolve/resolv.conf ]; then
        ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
    fi
fi

pkg_update
pkg_install dnsmasq

CONF="/etc/dnsmasq.d/lan.conf"
mkdir -p /etc/dnsmasq.d
if [ -f /etc/dnsmasq.conf ] && ! grep -qE '^conf-dir=/etc/dnsmasq.d' /etc/dnsmasq.conf \
    && [ ! -f /etc/default/dnsmasq ]; then
    echo "conf-dir=/etc/dnsmasq.d/,*.conf" >> /etc/dnsmasq.conf
fi

backup_file "$CONF"
{
    echo "# Généré par install_dnsmasq.sh"
    echo "interface=${DNS_INTERFACE}"
    echo "bind-interfaces"
    echo "listen-address=127.0.0.1,${DNS_IP}"
    echo
    echo "# DNS en amont (ne pas lire /etc/resolv.conf)"
    echo "no-resolv"
    for s in $DNS_UPSTREAM; do echo "server=${s}"; done
    echo "cache-size=1000"
    echo "domain-needed"
    echo "bogus-priv"
    echo
    echo "# Domaine local : noms de /etc/hosts complétés avec .${DNS_DOMAIN}"
    echo "domain=${DNS_DOMAIN}"
    echo "local=/${DNS_DOMAIN}/"
    echo "expand-hosts"
    echo "#address=/nas.${DNS_DOMAIN}/192.168.1.20"
    if [ -n "$DHCP_RANGE" ]; then
        echo
        echo "# DHCP"
        echo "dhcp-range=${DHCP_RANGE}"
        echo "dhcp-option=option:router,${DHCP_ROUTER}"
        echo "dhcp-option=option:dns-server,${DNS_IP}"
        echo "dhcp-authoritative"
    fi
} > "$CONF"

dnsmasq --test
systemctl enable dnsmasq
systemctl restart dnsmasq
check_service_status dnsmasq

ports=(53/tcp 53/udp)
[ -n "$DHCP_RANGE" ] && ports+=(67/udp)
open_ports "${ports[@]}"

echo
echo "✅ dnsmasq installé : DNS sur ${DNS_IP}:53${DHCP_RANGE:+, DHCP ${DHCP_RANGE}}"
echo "Configuration : ${CONF}"
echo "Test          : dig @${DNS_IP} debian.org"
