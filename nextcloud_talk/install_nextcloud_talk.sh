#!/usr/bin/env bash
# Ajout de Nextcloud Talk (application spreed) à une instance Nextcloud existante,
# avec un serveur TURN coturn déclaré automatiquement dans Talk.
#
# Variables :
#   NC_DIR      dossier de Nextcloud (défaut : /var/www/nextcloud)
#   TURN_HOST   nom public du serveur TURN, ex. cloud.exemple.fr (obligatoire)

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

info "Nextcloud Talk - Discussion et visio dans Nextcloud"

NC_DIR="${NC_DIR:-/var/www/nextcloud}"
[ -f "${NC_DIR}/occ" ] || error_exit "Nextcloud introuvable dans ${NC_DIR} (définir NC_DIR) : cette procédure complète une instance existante"
[ -n "${TURN_HOST:-}" ] || error_exit "Définir TURN_HOST (nom public du serveur, ex. cloud.exemple.fr)"
OCC_USER="$(stat -c %U "${NC_DIR}/config/config.php")"
occ() { sudo -u "$OCC_USER" php "${NC_DIR}/occ" "$@"; }

info "Application Talk (spreed)"
if occ app:list --output=json | grep -q '"spreed"'; then
    occ app:enable spreed
    occ app:update spreed || true
else
    occ app:install spreed
fi

info "Serveur TURN coturn"
pkg_update
pkg_install coturn
TURN_SECRET="$(sed -nE 's/^static-auth-secret=(.+)/\1/p' /etc/turnserver.conf 2>/dev/null | head -n1)" || true
if [ -z "$TURN_SECRET" ]; then
    TURN_SECRET="$(openssl rand -hex 32)"
    backup_file /etc/turnserver.conf
    cat > /etc/turnserver.conf <<EOF
listening-port=3478
fingerprint
use-auth-secret
static-auth-secret=${TURN_SECRET}
realm=${TURN_HOST}
total-quota=0
bps-capacity=0
stale-nonce
no-multicast-peers
no-cli
EOF
    chmod 640 /etc/turnserver.conf
    chown root:turnserver /etc/turnserver.conf 2>/dev/null || true
fi
systemctl enable coturn
systemctl restart coturn
check_service_status coturn
open_ports 3478/tcp 3478/udp

info "Déclaration des serveurs STUN et TURN dans Talk"
occ talk:stun:list --output=json 2>/dev/null | grep -q "${TURN_HOST}:3478" || occ talk:stun:add "${TURN_HOST}:3478"
occ talk:turn:list --output=json 2>/dev/null | grep -q "${TURN_HOST}:3478" || occ talk:turn:add turn "${TURN_HOST}:3478" udp,tcp --secret="$TURN_SECRET"

echo
echo "✅ Nextcloud Talk activé, TURN ${TURN_HOST}:3478 déclaré"
echo "Vérifier : Paramètres d'administration > Talk > bouton de test du serveur TURN (coche verte)."
echo "Talk exige HTTPS : caméra et micro sont refusés par les navigateurs en HTTP."
