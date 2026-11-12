#!/usr/bin/env bash
# Installation de Fail2ban avec protection SSH (journal systemd) et prison « recidive ».
#
# Variables modifiables :
#   F2B_IGNOREIP  adresses jamais bannies (défaut : 127.0.0.1/8 ::1 + réseau local détecté
#                 + adresse de la session SSH en cours)
#   F2B_BANTIME   durée de bannissement (défaut : 1h)
#   F2B_MAXRETRY  échecs autorisés (défaut : 5)

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

info "Fail2ban - Protection contre les attaques par force brute"

LAN="$(ip -4 route show scope link 2>/dev/null | awk '!/docker|br-|veth/ {print $1; exit}')" || true
[[ "$LAN" =~ ^[0-9.]+/[0-9]+$ ]] || LAN=""
# Adresse de l'administrateur connecté en SSH (SSH_CLIENT n'existe plus sous sudo)
SSH_IP="${SSH_CLIENT:-}"
SSH_IP="${SSH_IP%% *}"
if [ -z "$SSH_IP" ]; then
    SSH_IP="$(who -m --ips 2>/dev/null | awk '{print $NF}' | tr -d '()')" || true
fi
[[ "$SSH_IP" =~ ^[0-9a-fA-F.:]+$ ]] || SSH_IP=""
F2B_IGNOREIP="${F2B_IGNOREIP:-127.0.0.1/8 ::1 ${LAN} ${SSH_IP}}"
F2B_BANTIME="${F2B_BANTIME:-1h}"
F2B_MAXRETRY="${F2B_MAXRETRY:-5}"

pkg_update
case "$PKG_MANAGER" in
    apt) pkg_install fail2ban python3-systemd ;;
    dnf|yum)
        if is_redhat_family && [ "$OS_ID" != "fedora" ]; then pkg_install epel-release || true; fi
        pkg_install fail2ban fail2ban-systemd || pkg_install fail2ban
        ;;
    zypper|pacman) pkg_install fail2ban ;;
esac

JAIL_LOCAL=/etc/fail2ban/jail.local
backup_file "$JAIL_LOCAL"
# shellcheck disable=SC2086
cat > "$JAIL_LOCAL" <<EOF
# Généré par install_fail2ban.sh : seulement les réglages modifiés (voir jail.conf)
[DEFAULT]
# Adresses jamais bannies : la machine et le réseau d'administration
ignoreip = $(echo ${F2B_IGNOREIP})
bantime  = ${F2B_BANTIME}
findtime = 10m
maxretry = ${F2B_MAXRETRY}
# Lecture du journal systemd (pas de /var/log/auth.log sur Debian 12+)
backend  = systemd

[sshd]
enabled = true
port    = ssh

[recidive]
enabled  = true
logpath  = /var/log/fail2ban.log
backend  = auto
bantime  = 1w
findtime = 1d
maxretry = 3
EOF

fail2ban-client -t
systemctl enable fail2ban
systemctl restart fail2ban
sleep 2
check_service_status fail2ban
fail2ban-client status sshd

echo
echo "✅ Fail2ban actif (prisons sshd et recidive)"
echo "Adresses jamais bannies : $(echo ${F2B_IGNOREIP})"
echo "État   : sudo fail2ban-client status sshd"
echo "Débannir : sudo fail2ban-client set sshd unbanip <adresse>"
