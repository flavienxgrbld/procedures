#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "HAProxy - Load balancer haute performance"

echo "=== Installation de HAProxy ==="
pkg_install haproxy

# Configuration de base
cat > /etc/haproxy/haproxy.cfg <<'EOF'
global
    log stdout local0
    log stdout local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000

frontend main
    bind *:80
    stats enable
    stats uri /stats
    default_backend servers

backend servers
    server web1 127.0.0.1:8001 check
    server web2 127.0.0.1:8002 check
EOF

systemctl enable haproxy
systemctl restart haproxy

if command -v ufw >/dev/null 2>&1; then
    ufw allow 80/tcp
fi

echo
echo "✅ HAProxy installé avec succès"
echo "Configuration: /etc/haproxy/haproxy.cfg"
echo "Stats: http://votre-serveur/stats"
