#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Fail2ban - Protection contre attaques brute-force"

echo "=== Installation de Fail2ban ==="
pkg_install fail2ban

# Configuration
echo "=== Configuration de Fail2ban ==="
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

cat >> /etc/fail2ban/jail.local <<'EOF'

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
bantime = 3600
findtime = 600
maxretry = 5

[recidive]
enabled = true
port = all
logpath = /var/log/fail2ban.log
bantime = 604800
findtime = 86400
maxretry = 3
EOF

systemctl enable fail2ban
systemctl restart fail2ban

# Vérification
fail2ban-client status

echo
echo "✅ Fail2ban installé avec succès"
echo "Commandes utiles:"
echo "  fail2ban-client status - Voir le statut"
echo "  fail2ban-client status sshd - Voir les IPs bannies SSH"
