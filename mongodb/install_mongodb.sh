#!/usr/bin/env bash
# Installation de MongoDB Community 8.0 (dépôt officiel), avec un compte
# administrateur et l'authentification activée.
#
# Variables modifiables :
#   MONGO_ADMIN_PASS  mot de passe du compte admin (défaut : généré)
#   MONGO_NETWORK     oui pour écouter aussi sur l'adresse du serveur (défaut : non, 127.0.0.1 seulement)

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

info "MongoDB Community 8.0"

case "${OS_ID}:${OS_VERSION_ID}" in
    debian:12) REPO="deb [signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" ;;
    ubuntu:22.04) REPO="deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" ;;
    ubuntu:24.04) REPO="deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" ;;
    *) error_exit "MongoDB 8.0 : Debian 12, Ubuntu 22.04 ou 24.04 (détecté : ${OS_NAME} ${OS_VERSION_ID})" ;;
esac
grep -qw avx /proc/cpuinfo || warn "Le processeur n'annonce pas AVX : MongoDB 5.0 et plus récents ne démarreront pas (VM : activer le mode CPU « host »)"

MONGO_ADMIN_PASS="${MONGO_ADMIN_PASS:-$(random_password 24)}"
MONGO_NETWORK="${MONGO_NETWORK:-non}"

pkg_update
pkg_install gnupg curl ca-certificates
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | gpg --dearmor --yes -o /usr/share/keyrings/mongodb-server-8.0.gpg
echo "$REPO" > /etc/apt/sources.list.d/mongodb-org-8.0.list
pkg_update
pkg_install mongodb-org
systemctl enable mongod
systemctl restart mongod

info "Attente de mongod"
for _ in $(seq 1 30); do mongosh --quiet --eval 'db.runCommand({ping:1}).ok' >/dev/null 2>&1 && break; sleep 2; done

CONF=/etc/mongod.conf
if grep -qE '^ *authorization: *enabled' "$CONF"; then
    warn "L'authentification est déjà activée : compte admin non recréé"
    NEW_ADMIN=0
else
    info "Création du compte administrateur"
    mongosh --quiet admin --eval "db.createUser({user: 'admin', pwd: '${MONGO_ADMIN_PASS}', roles: ['root']})"
    NEW_ADMIN=1
    backup_file "$CONF"
    if grep -q '^#\?security:' "$CONF"; then
        sed -i 's/^#\?security:.*/security:\n  authorization: enabled/' "$CONF"
    else
        printf '\nsecurity:\n  authorization: enabled\n' >> "$CONF"
    fi
fi

if [ "$MONGO_NETWORK" = "oui" ]; then
    IP="$(primary_ip)"
    sed -i -E "s/^( *bindIp:).*/\1 127.0.0.1,${IP}/" "$CONF"
    LAN="$(ip -4 route show scope link 2>/dev/null | awk '!/docker|br-|veth/ {print $1; exit}')" || true
    if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active" && [ -n "$LAN" ]; then
        ufw allow from "$LAN" to any port 27017 proto tcp >/dev/null
    fi
fi

systemctl restart mongod
check_service_status mongod
[ "$NEW_ADMIN" = 1 ] && save_credentials /root/mongodb_identifiants.txt "Compte : admin (base d'authentification admin)" "Mot de passe : ${MONGO_ADMIN_PASS}"

echo
echo "✅ MongoDB $(mongod --version | awk 'NR==1{print $3}') installé, authentification activée"
echo "Connexion : mongosh -u admin -p --authenticationDatabase admin"
