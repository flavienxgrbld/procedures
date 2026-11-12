#!/usr/bin/env bash
# Stockage objet compatible S3.
# L'édition open source de MinIO n'est plus distribuée (binaires retirés, dépôt archivé).
#   - Avec MINIO_DEB=/chemin/vers/minio_xxx.deb : installe et configure AIStor Free
#     (paquet téléchargé à la main sur https://min.io/download, inscription requise).
#   - Sans MINIO_DEB : installe SeaweedFS, alternative libre (procédure seaweedfs).
#
# Variables (AIStor) :
#   MINIO_DEB, MINIO_VOLUMES (défaut : /srv/s3), MINIO_ROOT_USER (défaut : admin),
#   MINIO_ROOT_PASSWORD (défaut : généré)

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

info "Stockage objet S3 (AIStor Free ou SeaweedFS)"

if [ -z "${MINIO_DEB:-}" ]; then
    warn "MINIO_DEB non défini : installation de SeaweedFS, alternative libre à MinIO"
    [ -f "${SCRIPT_DIR}/../seaweedfs/install_seaweedfs.sh" ] || error_exit "Procédure seaweedfs introuvable dans le dépôt"
    exec bash "${SCRIPT_DIR}/../seaweedfs/install_seaweedfs.sh"
fi

[ "$PKG_MANAGER" = "apt" ] || error_exit "Paquet .deb : Debian ou Ubuntu requis"
[ -f "$MINIO_DEB" ] || error_exit "Fichier introuvable : $MINIO_DEB"
MINIO_VOLUMES="${MINIO_VOLUMES:-/srv/s3}"
MINIO_ROOT_USER="${MINIO_ROOT_USER:-admin}"
MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-$(random_password 24)}"
[ "${#MINIO_ROOT_PASSWORD}" -ge 8 ] || error_exit "MINIO_ROOT_PASSWORD : 8 caractères minimum"

DEBIAN_FRONTEND=noninteractive apt-get install -y "$(realpath "$MINIO_DEB")"

id minio-user >/dev/null 2>&1 || useradd --system --user-group --no-create-home --shell /usr/sbin/nologin minio-user
mkdir -p "$MINIO_VOLUMES"
chown minio-user:minio-user "$MINIO_VOLUMES"

backup_file /etc/default/minio
(umask 077; cat > /etc/default/minio) <<EOF
MINIO_ROOT_USER=${MINIO_ROOT_USER}
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}
MINIO_VOLUMES="${MINIO_VOLUMES}"
MINIO_OPTS="--console-address :9001"
EOF

systemctl enable minio
systemctl restart minio
check_service_status minio
open_ports 9000/tcp 9001/tcp

save_credentials /root/minio_identifiants.txt "Console : http://<serveur>:9001" "Utilisateur : ${MINIO_ROOT_USER}" "Mot de passe : ${MINIO_ROOT_PASSWORD}"
echo
echo "✅ AIStor Free installé : API http://$(primary_ip):9000, console :9001"
echo "Enregistrer la clé de licence gratuite selon la documentation AIStor."
