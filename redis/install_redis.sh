#!/usr/bin/env bash
# Installation de Redis (paquet de la distribution) avec mot de passe et limite mémoire.
#
# Variables modifiables :
#   REDIS_PASS       mot de passe (défaut : généré)
#   REDIS_MAXMEMORY  mémoire maximale (défaut : 256mb)
#   REDIS_POLICY     politique d'éviction : noeviction (défaut, données conservées) ou allkeys-lru (cache)
#   REDIS_CLIENTS    adresses autorisées depuis le réseau, ex. "192.168.1.21 192.168.1.22" (défaut : aucune)

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

info "Redis - Base clé/valeur en mémoire"

REDIS_MAXMEMORY="${REDIS_MAXMEMORY:-256mb}"
REDIS_POLICY="${REDIS_POLICY:-noeviction}"
CONF=/etc/redis/redis.conf

pkg_update
pkg_install redis-server python3

set_conf() {  # set_conf clé valeur (remplace la ligne, commentée ou non)
    local k="$1" v="$2"
    python3 - "$CONF" "$k" "$v" <<'PY'
import re, sys
path, k, v = sys.argv[1:4]
s = open(path).read()
line = f"{k} {v}"
pat = re.compile(rf"^#?\s*{re.escape(k)}\s.*$", re.M)
s = pat.sub(lambda m: line, s, count=1) if pat.search(s) else s.rstrip("\n") + "\n" + line + "\n"
open(path, "w").write(s)
PY
}

backup_file "$CONF"
if grep -qE '^requirepass ' "$CONF" && [ -z "${REDIS_PASS:-}" ]; then
    info "Mot de passe existant conservé"
    REDIS_PASS="$(awk '/^requirepass /{print $2}' "$CONF")"
else
    REDIS_PASS="${REDIS_PASS:-$(random_password 32)}"
    set_conf requirepass "$REDIS_PASS"
fi
set_conf maxmemory "$REDIS_MAXMEMORY"
set_conf maxmemory-policy "$REDIS_POLICY"
if [ -n "${REDIS_CLIENTS:-}" ]; then
    set_conf bind "127.0.0.1 -::1 $(primary_ip)"
    if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
        for c in $REDIS_CLIENTS; do ufw allow from "$c" to any port 6379 proto tcp >/dev/null; done
    fi
else
    set_conf bind "127.0.0.1 -::1"
fi
chown redis:redis "$CONF"; chmod 640 "$CONF"

systemctl enable redis-server
systemctl restart redis-server
check_service_status redis-server
REDISCLI_AUTH="$REDIS_PASS" redis-cli ping | grep -q PONG || error_exit "Redis ne répond pas avec le mot de passe"

save_credentials /root/redis_identifiants.txt "Redis : $(grep '^bind ' "$CONF")" "Mot de passe : ${REDIS_PASS}"
echo
echo "✅ Redis installé (politique ${REDIS_POLICY}, ${REDIS_MAXMEMORY} max)"
echo "Test : REDISCLI_AUTH=<mot de passe> redis-cli ping"
