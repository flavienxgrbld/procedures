#!/usr/bin/env bash
# Installation d'ownCloud Infinite Scale (oCIS, binaire officiel) en service systemd.
#
# Variables modifiables :
#   OCIS_VERSION  version (défaut : dernière publiée)
#   OCIS_URL      adresse utilisée dans le navigateur (défaut : https://<ip>:9200)

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

info "ownCloud Infinite Scale (oCIS)"
command -v systemctl >/dev/null 2>&1 || error_exit "systemd est requis"

OCIS_VERSION="${OCIS_VERSION:-$(github_latest_tag owncloud/ocis v8.2.3)}"
OCIS_VERSION="${OCIS_VERSION#v}"
OCIS_URL="${OCIS_URL:-https://$(primary_ip):9200}"
case "$(uname -m)" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; *) error_exit "Architecture non gérée" ;; esac

pkg_install curl
NAME="ocis-${OCIS_VERSION}-linux-${ARCH}"
BASE="https://github.com/owncloud/ocis/releases/download/v${OCIS_VERSION}"
WORK="$(mktemp -d)"; add_temp_file "$WORK"
download_file "${BASE}/${NAME}" "${WORK}/${NAME}"
download_file "${BASE}/${NAME}.sha256" "${WORK}/${NAME}.sha256"
(cd "$WORK" && sha256sum -c "${NAME}.sha256") || error_exit "Somme de contrôle invalide"
install -m 0755 "${WORK}/${NAME}" /usr/local/bin/ocis
ocis version | head -n2

id ocis >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin ocis
mkdir -p /etc/ocis /srv/ocis
chown ocis:ocis /etc/ocis /srv/ocis

if [ ! -f /etc/ocis/ocis.yaml ]; then
    info "Initialisation de la configuration (compte admin)"
    INIT_OUT="$(sudo -u ocis env OCIS_CONFIG_DIR=/etc/ocis OCIS_BASE_DATA_PATH=/srv/ocis ocis init --insecure true 2>&1)"
    # Sortie de « ocis init » : lignes « user : admin » et « password : ... »
    ADMIN_PASS="$(printf '%s\n' "$INIT_OUT" | sed -nE 's/^[[:space:]]*password[[:space:]]*:[[:space:]]*(.+)$/\1/p' | tail -n1)"
    printf '%s\n' "$INIT_OUT" | grep -iv password || true
    [ -n "$ADMIN_PASS" ] && save_credentials /root/ocis_identifiants.txt "oCIS : ${OCIS_URL}" "Compte : admin" "Mot de passe : ${ADMIN_PASS}"
fi

cat > /etc/systemd/system/ocis.service <<EOF
[Unit]
Description=ownCloud Infinite Scale
After=network.target

[Service]
User=ocis
Group=ocis
Environment=OCIS_CONFIG_DIR=/etc/ocis
Environment=OCIS_BASE_DATA_PATH=/srv/ocis
Environment=OCIS_URL=${OCIS_URL}
Environment=PROXY_HTTP_ADDR=0.0.0.0:9200
Environment=OCIS_INSECURE=true
ExecStart=/usr/local/bin/ocis server
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable ocis
systemctl restart ocis
sleep 5
check_service_status ocis
open_ports 9200/tcp

echo
echo "✅ oCIS ${OCIS_VERSION} installé : ${OCIS_URL} (certificat autosigné)"
echo "Compte admin : /root/ocis_identifiants.txt"
