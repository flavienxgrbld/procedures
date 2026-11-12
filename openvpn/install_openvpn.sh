#!/usr/bin/env bash
# Serveur OpenVPN avec PKI easy-rsa, routage vers le réseau local et premier client (.ovpn).
#
# Variables :
#   VPN_PUBLIC   adresse ou nom public du serveur, utilisée par les clients (obligatoire)
#   VPN_LAN      réseau local à rendre accessible (défaut : réseau détecté, ex. 192.168.1.0/24)
#   VPN_DNS      DNS poussé aux clients (défaut : passerelle actuelle)
#   VPN_CLIENT   nom du premier client (défaut : client1)
#   VPN_NET      réseau du VPN (défaut : 10.8.0.0/24)
#
# Ajouter un client plus tard : sudo VPN_PUBLIC=... VPN_CLIENT=bob bash install_openvpn.sh

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

info "OpenVPN - Accès distant au réseau de l'entreprise"

[ -n "${VPN_PUBLIC:-}" ] || error_exit "Définir VPN_PUBLIC (adresse IP publique ou nom DNS du serveur)"
IFACE="$(ip -4 route show default | awk '{print $5; exit}')"
VPN_LAN="${VPN_LAN:-$(ip -4 route show dev "$IFACE" scope link | awk '{print $1; exit}')}"
VPN_DNS="${VPN_DNS:-$(ip -4 route show default | awk '{print $3; exit}')}"
VPN_CLIENT="${VPN_CLIENT:-client1}"
VPN_NET="${VPN_NET:-10.8.0.0/24}"
PKI_DIR="/etc/openvpn/easy-rsa"
SRV_DIR="/etc/openvpn/server"
CLIENT_DIR="/root/openvpn-clients"

cidr2mask() { local i m=""; for i in 1 2 3 4; do local b=$(( ${1} >= i*8 ? 8 : ( ${1} > (i-1)*8 ? ${1}-(i-1)*8 : 0 ) )); m+="$(( 256 - 2**(8-b) ))"; [ $i -lt 4 ] && m+="."; done; echo "$m"; }
LAN_ADDR="${VPN_LAN%/*}"; LAN_MASK="$(cidr2mask "${VPN_LAN#*/}")"
NET_ADDR="${VPN_NET%/*}"; NET_MASK="$(cidr2mask "${VPN_NET#*/}")"

pkg_update
pkg_install openvpn easy-rsa iptables
export EASYRSA_BATCH=1

if [ ! -f "${PKI_DIR}/pki/ca.crt" ]; then
    info "Autorité de certification et certificat du serveur"
    rm -rf "$PKI_DIR"
    make-cadir "$PKI_DIR"
    cd "$PKI_DIR"
    ./easyrsa init-pki
    EASYRSA_REQ_CN="CA-VPN-$(hostname -s)" ./easyrsa build-ca nopass
    ./easyrsa build-server-full serveur nopass
    ./easyrsa gen-crl
    openvpn --genkey secret "${PKI_DIR}/ta.key"
    chmod 700 "$PKI_DIR"
fi
cd "$PKI_DIR"

mkdir -p "$SRV_DIR" /var/log/openvpn
cp pki/ca.crt pki/issued/serveur.crt pki/private/serveur.key pki/crl.pem ta.key "$SRV_DIR/"
chmod 600 "${SRV_DIR}/serveur.key" "${SRV_DIR}/ta.key"
chmod 644 "${SRV_DIR}/crl.pem"

cat > "${SRV_DIR}/server.conf" <<EOF
# Généré par install_openvpn.sh
port 1194
proto udp
dev tun
ca ca.crt
cert serveur.crt
key serveur.key
dh none
tls-crypt ta.key
crl-verify crl.pem
server ${NET_ADDR} ${NET_MASK}
push "route ${LAN_ADDR} ${LAN_MASK}"
push "dhcp-option DNS ${VPN_DNS}"
keepalive 10 120
data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn/status.log
verb 3
EOF

info "Routage IP et traduction d'adresses vers ${VPN_LAN}"
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-vpn.conf
sysctl -q --system
iptables -t nat -C POSTROUTING -s "$VPN_NET" -o "$IFACE" -j MASQUERADE 2>/dev/null \
    || iptables -t nat -A POSTROUTING -s "$VPN_NET" -o "$IFACE" -j MASQUERADE
echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections
pkg_install iptables-persistent
netfilter-persistent save >/dev/null
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    ufw allow 1194/udp >/dev/null
    sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
    ufw reload >/dev/null
fi

systemctl enable openvpn-server@server
systemctl restart openvpn-server@server
check_service_status openvpn-server@server

info "Client ${VPN_CLIENT}"
[ -f "pki/issued/${VPN_CLIENT}.crt" ] || ./easyrsa build-client-full "$VPN_CLIENT" nopass
mkdir -p "$CLIENT_DIR"; chmod 700 "$CLIENT_DIR"
OVPN="${CLIENT_DIR}/${VPN_CLIENT}.ovpn"
{
cat <<EOF
client
dev tun
proto udp
remote ${VPN_PUBLIC} 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305
verb 3
EOF
echo "<ca>";        cat pki/ca.crt;                                          echo "</ca>"
echo "<cert>";      sed -n '/BEGIN/,/END/p' "pki/issued/${VPN_CLIENT}.crt";  echo "</cert>"
echo "<key>";       cat "pki/private/${VPN_CLIENT}.key";                     echo "</key>"
echo "<tls-crypt>"; cat ta.key;                                              echo "</tls-crypt>"
} > "$OVPN"
chmod 600 "$OVPN"

echo
echo "✅ Serveur OpenVPN actif (UDP 1194, réseau ${VPN_NET} -> ${VPN_LAN})"
echo "Fichier client : ${OVPN} (à transmettre par un canal sûr)"
echo "Révoquer : cd ${PKI_DIR} && sudo ./easyrsa revoke <nom> && sudo ./easyrsa gen-crl && sudo cp pki/crl.pem ${SRV_DIR}/"
