#!/usr/bin/env bash
# Installation d'Alertmanager (binaire officiel) sous forme de service systemd.
#
# Variables modifiables :
#   ALERTMANAGER_VERSION  version à installer (défaut : dernière version publiée)

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
command -v systemctl >/dev/null 2>&1 || error_exit "systemd est requis"

info "Alertmanager - Gestionnaire d'alertes Prometheus"

ALERTMANAGER_VERSION="${ALERTMANAGER_VERSION:-$(github_latest_tag prometheus/alertmanager v0.35.0)}"
ALERTMANAGER_VERSION="${ALERTMANAGER_VERSION#v}"
ALERTMANAGER_USER="alertmanager"
CONF_DIR="/etc/alertmanager"
DATA_DIR="/var/lib/alertmanager"

case "$(uname -m)" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    armv7l) ARCH="armv7" ;;
    *) error_exit "Architecture non gérée : $(uname -m)" ;;
esac

pkg_install curl tar

if ! id "$ALERTMANAGER_USER" >/dev/null 2>&1; then
    useradd --system --no-create-home --shell /usr/sbin/nologin "$ALERTMANAGER_USER"
fi

info "Téléchargement d'Alertmanager ${ALERTMANAGER_VERSION} (${ARCH})"
WORK_DIR="$(mktemp -d)"
add_temp_file "$WORK_DIR"
NAME="alertmanager-${ALERTMANAGER_VERSION}.linux-${ARCH}"
BASE_URL="https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}"
download_file "${BASE_URL}/${NAME}.tar.gz" "${WORK_DIR}/${NAME}.tar.gz"
download_file "${BASE_URL}/sha256sums.txt" "${WORK_DIR}/sha256sums.txt"
(cd "$WORK_DIR" && grep " ${NAME}.tar.gz\$" sha256sums.txt | sha256sum -c -) \
    || error_exit "Somme de contrôle invalide pour ${NAME}.tar.gz"
tar -xzf "${WORK_DIR}/${NAME}.tar.gz" -C "$WORK_DIR"

install -m 0755 "${WORK_DIR}/${NAME}/alertmanager" "${WORK_DIR}/${NAME}/amtool" /usr/local/bin/

mkdir -p "$CONF_DIR" "$DATA_DIR"
if [ ! -f "${CONF_DIR}/alertmanager.yml" ]; then
    install -m 0644 "${WORK_DIR}/${NAME}/alertmanager.yml" "${CONF_DIR}/alertmanager.yml"
else
    info "Configuration existante conservée : ${CONF_DIR}/alertmanager.yml"
fi
chown -R "$ALERTMANAGER_USER:$ALERTMANAGER_USER" "$CONF_DIR" "$DATA_DIR"

amtool check-config "${CONF_DIR}/alertmanager.yml"

cat > /etc/systemd/system/alertmanager.service <<EOF
[Unit]
Description=Prometheus Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=${ALERTMANAGER_USER}
Group=${ALERTMANAGER_USER}
ExecStart=/usr/local/bin/alertmanager \\
    --config.file=${CONF_DIR}/alertmanager.yml \\
    --storage.path=${DATA_DIR}
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now alertmanager
systemctl restart alertmanager
sleep 2
check_service_status alertmanager

open_ports 9093/tcp

echo
echo "✅ Alertmanager ${ALERTMANAGER_VERSION} installé"
echo "Interface : http://$(hostname -I | awk '{print $1}'):9093"
echo "Configuration : ${CONF_DIR}/alertmanager.yml (définir les récepteurs avant usage)"
