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

info "Dnsmasq - Serveur DNS/DHCP léger"

echo "=== Installation de Dnsmasq ==="
pkg_install dnsmasq

# Configuration
cat > /etc/dnsmasq.conf <<'EOF'
# DNS
listen-address=127.0.0.1
port=53
resolv-file=/etc/resolv.conf.d/resolv.conf.dnsmasq

# DHCP (optionnel)
#dhcp-range=192.168.1.100,192.168.1.200,12h
#dhcp-option=option:router,192.168.1.1

# Redirection DNS personnalisée
#address=/example.local/192.168.1.100
EOF

systemctl enable dnsmasq
systemctl restart dnsmasq

if command -v ufw >/dev/null 2>&1; then
    ufw allow 53/tcp
    ufw allow 53/udp
    ufw allow 67/udp
fi

echo
echo "✅ Dnsmasq installé avec succès"
echo "Port: 53 (DNS), 67 (DHCP)"
echo "Configuration: /etc/dnsmasq.conf"
