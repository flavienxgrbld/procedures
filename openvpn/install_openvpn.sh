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

info "OpenVPN - Serveur VPN"

echo "=== Installation d'OpenVPN ==="
pkg_install openvpn openssl easy-rsa

# Initialisation PKI
mkdir -p /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa

# Copie EasyRSA
cp /usr/share/easy-rsa/* .

# Initialiser PKI
./easyrsa init-pki

# Créer CA
./easyrsa build-ca nopass

# Créer certificat serveur
./easyrsa gen-req server nopass
./easyrsa sign-req server server

# Générer clés de diffie-hellman
./easyrsa gen-dh

# Configuration serveur OpenVPN
cat > /etc/openvpn/server.conf <<'EOF'
port 1194
proto udp
dev tun

ca /etc/openvpn/easy-rsa/pki/ca.crt
cert /etc/openvpn/easy-rsa/pki/issued/server.crt
key /etc/openvpn/easy-rsa/pki/private/server.key
dh /etc/openvpn/easy-rsa/pki/dh.pem

server 10.8.0.0 255.255.255.0
push "route 10.8.0.0 255.255.255.0"

keepalive 20 120
cipher AES-256-GCM

persist-key
persist-tun
status /var/log/openvpn/status.log
log-append /var/log/openvpn/openvpn.log
verb 3
EOF

mkdir -p /var/log/openvpn
systemctl enable openvpn@server
systemctl start openvpn@server

if command -v ufw >/dev/null 2>&1; then
    ufw allow 1194/udp
fi

echo
echo "✅ OpenVPN serveur installé avec succès"
echo "Port: 1194/udp"
echo "Vous devez générer les clés client avec easy-rsa"
