#!/usr/bin/env bash
# Installation d'HAProxy en répartiteur de charge HTTP, avec page de statistiques
# protégée sur un port séparé.
#
# Variables :
#   HAPROXY_BACKENDS  serveurs web à répartir, ex. "192.168.1.21:80 192.168.1.22:80" (obligatoire)
#   HAPROXY_PORT      port d'écoute public (défaut : 80)
#   HAPROXY_CHECK     chemin testé sur chaque serveur (défaut : /)
#   STATS_PASS        mot de passe de la page /stats (défaut : généré ; utilisateur admin)

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

info "HAProxy - Répartiteur de charge"

[ -n "${HAPROXY_BACKENDS:-}" ] || error_exit "Définir HAPROXY_BACKENDS, ex. : sudo HAPROXY_BACKENDS=\"192.168.1.21:80 192.168.1.22:80\" bash install_haproxy.sh"
HAPROXY_PORT="${HAPROXY_PORT:-80}"
HAPROXY_CHECK="${HAPROXY_CHECK:-/}"
STATS_PASS="${STATS_PASS:-$(random_password 20)}"

pkg_update
pkg_install haproxy
haproxy -v | head -n1

CFG=/etc/haproxy/haproxy.cfg
[ -f "${CFG}.orig" ] || cp "$CFG" "${CFG}.orig"
backup_file "$CFG"

servers=""
i=1
for b in $HAPROXY_BACKENDS; do
    servers+="    server web${i} ${b} check"$'\n'
    i=$((i + 1))
done

cat > "$CFG" <<EOF
# Généré par install_haproxy.sh (configuration d'origine : ${CFG}.orig)
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    option  forwardfor
    timeout connect 5s
    timeout client  50s
    timeout server  50s

frontend web
    bind *:${HAPROXY_PORT}
    default_backend serveurs_web

backend serveurs_web
    balance roundrobin
    option httpchk GET ${HAPROXY_CHECK}
${servers}
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth admin:${STATS_PASS}
EOF
chmod 640 "$CFG"

haproxy -c -f "$CFG"
systemctl enable haproxy
systemctl restart haproxy
check_service_status haproxy
open_ports "${HAPROXY_PORT}/tcp" 8404/tcp

save_credentials /root/haproxy_identifiants.txt "Statistiques : http://<serveur>:8404/stats" "Utilisateur  : admin" "Mot de passe : ${STATS_PASS}"

echo
echo "✅ HAProxy répartit le port ${HAPROXY_PORT} vers : ${HAPROXY_BACKENDS}"
echo "Statistiques : http://$(hostname -I | awk '{print $1}'):8404/stats (admin, mot de passe dans /root/haproxy_identifiants.txt)"
