#!/usr/bin/env bash
# Installation de Gitea (binaire officiel, dernière version) en service systemd.
#
# Variables modifiables :
#   GITEA_VERSION  version à installer, ex. 28.3.0 (défaut : dernière publiée)
#   GITEA_PORT     port HTTP (défaut : 3000)

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

info "Gitea - Forge Git auto-hébergée"
command -v systemctl >/dev/null 2>&1 || error_exit "systemd est requis"

GITEA_VERSION="${GITEA_VERSION:-$(github_latest_tag go-gitea/gitea v28.3.0)}"
GITEA_VERSION="${GITEA_VERSION#v}"
GITEA_PORT="${GITEA_PORT:-3000}"
case "$(uname -m)" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    armv7l) ARCH="arm-6" ;;
    *) error_exit "Architecture non gérée : $(uname -m)" ;;
esac

pkg_update
pkg_install git curl

if ! id git >/dev/null 2>&1; then
    useradd --system --shell /bin/bash --create-home --home-dir /home/git --user-group git
fi
mkdir -p /var/lib/gitea/{custom,data,log} /etc/gitea
chown -R git:git /var/lib/gitea
chmod -R 750 /var/lib/gitea
if [ ! -f /etc/gitea/app.ini ]; then
    # L'assistant web doit pouvoir écrire app.ini
    chown root:git /etc/gitea
    chmod 770 /etc/gitea
fi

info "Téléchargement de Gitea ${GITEA_VERSION} (${ARCH})"
NAME="gitea-${GITEA_VERSION}-linux-${ARCH}"
BASE="https://github.com/go-gitea/gitea/releases/download/v${GITEA_VERSION}"
TMP_DIR="$(mktemp -d)"
add_temp_file "$TMP_DIR"
download_file "${BASE}/${NAME}" "${TMP_DIR}/${NAME}"
download_file "${BASE}/${NAME}.sha256" "${TMP_DIR}/${NAME}.sha256"
(cd "$TMP_DIR" && sha256sum -c "${NAME}.sha256") || error_exit "Somme de contrôle invalide"
install -m 0755 "${TMP_DIR}/${NAME}" /usr/local/bin/gitea
/usr/local/bin/gitea --version

cat > /etc/systemd/system/gitea.service <<EOF
[Unit]
Description=Gitea
After=network.target

[Service]
Type=simple
User=git
Group=git
WorkingDirectory=/var/lib/gitea
ExecStart=/usr/local/bin/gitea web --config /etc/gitea/app.ini --port ${GITEA_PORT}
Restart=always
Environment=USER=git HOME=/home/git GITEA_WORK_DIR=/var/lib/gitea

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable gitea
systemctl restart gitea
sleep 2
check_service_status gitea
open_ports "${GITEA_PORT}/tcp"

echo
echo "✅ Gitea ${GITEA_VERSION} installé"
if [ -f /etc/gitea/app.ini ]; then
    echo "Configuration existante conservée (/etc/gitea/app.ini)"
else
    echo "1. Assistant : http://$(hostname -I | awk '{print $1}'):${GITEA_PORT}"
    echo "2. Ensuite, verrouiller la configuration :"
    echo "   sudo chmod 750 /etc/gitea && sudo chmod 640 /etc/gitea/app.ini"
fi
