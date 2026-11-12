#!/usr/bin/env bash
# Serveur WireGuard avec routage vers le réseau local et premier client (fichier .conf + QR code).
#
# Variables :
#   WG_PUBLIC  adresse ou nom public du serveur (obligatoire)
#   WG_CLIENT  nom du client à ajouter (défaut : client1) ; relancer pour en ajouter d'autres
#   WG_NET     réseau du VPN (défaut : 10.10.0.0/24)
#   WG_PORT    port UDP (défaut : 51820)
#   WG_DNS     DNS donné aux clients (défaut : passerelle actuelle)

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
is_debian_family || error_exit "Ce script est prévu pour Debian ou Ubuntu"

info "WireGuard - VPN"

[ -n "${WG_PUBLIC:-}" ] || error_exit "Définir WG_PUBLIC (adresse IP publique ou nom DNS du serveur)"
WG_CLIENT="${WG_CLIENT:-client1}"
WG_NET="${WG_NET:-10.10.0.0/24}"
WG_PORT="${WG_PORT:-51820}"
WG_DNS="${WG_DNS:-$(ip -4 route show default | awk '{print $3; exit}')}"
IFACE="$(ip -4 route show default | awk '{print $5; exit}')"
LAN="$(ip -4 route show dev "$IFACE" scope link | awk '{print $1; exit}')"
PREFIX="${WG_NET%.*}"     # ex. 10.10.0
MASK="${WG_NET#*/}"
CONF=/etc/wireguard/wg0.conf
CLIENT_DIR=/root/wireguard-clients

pkg_update
pkg_install wireguard iptables qrencode
mkdir -p /etc/wireguard "$CLIENT_DIR"; chmod 700 /etc/wireguard "$CLIENT_DIR"

if [ ! -f "$CONF" ]; then
    (umask 077; wg genkey > /etc/wireguard/serveur.key)
    wg pubkey < /etc/wireguard/serveur.key > /etc/wireguard/serveur.pub
    cat > "$CONF" <<EOF
[Interface]
Address = ${PREFIX}.1/${MASK}
ListenPort = ${WG_PORT}
PrivateKey = $(cat /etc/wireguard/serveur.key)
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -s ${WG_NET} -o ${IFACE} -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -s ${WG_NET} -o ${IFACE} -j MASQUERADE
EOF
    chmod 600 "$CONF"
fi

echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-wireguard.conf
sysctl -q --system

if grep -q "^# ${WG_CLIENT}\$" "$CONF"; then
    warn "Le client ${WG_CLIENT} existe déjà"
else
    used="$(grep -oE "AllowedIPs = ${PREFIX//./\\.}\.[0-9]+" "$CONF" | awk -F. '{print $NF}' | sort -n | tail -n1)" || true
    N=$(( ${used:-1} + 1 ))
    [ "$N" -lt 255 ] || error_exit "Plus d'adresse libre dans ${WG_NET}"
    CKEY="$(wg genkey)"; CPUB="$(printf '%s' "$CKEY" | wg pubkey)"; PSK="$(wg genpsk)"
    cat >> "$CONF" <<EOF

[Peer]
# ${WG_CLIENT}
PublicKey = ${CPUB}
PresharedKey = ${PSK}
AllowedIPs = ${PREFIX}.${N}/32
EOF
    CFILE="${CLIENT_DIR}/${WG_CLIENT}.conf"
    (umask 077; cat > "$CFILE") <<EOF
[Interface]
PrivateKey = ${CKEY}
Address = ${PREFIX}.${N}/32
DNS = ${WG_DNS}

[Peer]
PublicKey = $(cat /etc/wireguard/serveur.pub)
PresharedKey = ${PSK}
Endpoint = ${WG_PUBLIC}:${WG_PORT}
AllowedIPs = ${WG_NET}, ${LAN}
PersistentKeepalive = 25
EOF
    info "Client ${WG_CLIENT} : ${CFILE} (adresse ${PREFIX}.${N})"
    qrencode -t ansiutf8 < "$CFILE" || true
fi

systemctl enable wg-quick@wg0
if systemctl is-active --quiet wg-quick@wg0; then
    wg syncconf wg0 <(wg-quick strip wg0)
else
    systemctl start wg-quick@wg0
fi
check_service_status wg-quick@wg0
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    ufw allow "${WG_PORT}/udp" >/dev/null
    sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
    ufw reload >/dev/null
fi

echo
echo "✅ WireGuard actif (UDP ${WG_PORT}, réseau ${WG_NET} -> ${LAN})"
echo "Fichiers clients : ${CLIENT_DIR}/ (scanner le QR code avec l'application WireGuard)"
echo "La clé privée du serveur (/etc/wireguard/serveur.key) ne doit jamais être communiquée."
