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

info "WireGuard - VPN moderne et performant"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

echo "=== Installation de WireGuard ==="
case "$PKG_MANAGER" in
    apt)
        pkg_install wireguard wireguard-tools wireguard-dkms linux-headers-$(uname -r)
        ;;
    dnf|yum)
        pkg_install wireguard-tools wireguard-dkms kernel-devel-$(uname -r)
        ;;
    zypper)
        pkg_install wireguard-kmp-default wireguard-tools
        ;;
    pacman)
        pkg_install wireguard-tools
        ;;
esac

# Création dossier configuration
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard

# Génération des clés
echo "=== Génération des clés WireGuard ==="
cd /etc/wireguard
wg genkey | tee privatekey | wg pubkey > publickey
chmod 600 privatekey

# Configuration exemple serveur
cat > /etc/wireguard/wg0.conf <<'EOF'
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = [YOUR_PRIVATE_KEY_HERE]
PostUp = iptables -A FORWARD -i %i -o eth0 -j ACCEPT; iptables -A FORWARD -i eth0 -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -o eth0 -j ACCEPT; iptables -D FORWARD -i eth0 -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Client exemple
# [Peer]
# PublicKey = [CLIENT_PUBLIC_KEY]
# AllowedIPs = 10.0.0.2/32
EOF

chmod 600 /etc/wireguard/wg0.conf

# Configuration firewall
if command -v ufw >/dev/null 2>&1; then
    ufw allow 51820/udp
    ufw allow in on wg0
fi

# Activation interface
wg-quick up wg0
systemctl enable wg-quick@wg0

echo
echo "✅ WireGuard installé avec succès"
echo "Port: 51820 (UDP)"
echo "Clés générées dans /etc/wireguard/"
echo "Configuration: /etc/wireguard/wg0.conf"
echo "Clé privée: $(cat /etc/wireguard/privatekey)"
echo "Clé publique: $(cat /etc/wireguard/publickey)"
