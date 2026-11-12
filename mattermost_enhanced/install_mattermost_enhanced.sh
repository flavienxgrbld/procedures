#!/usr/bin/env bash
# Installation de Mattermost (archive officielle) avec PostgreSQL, en service systemd.
#
# Variables modifiables :
#   MM_VERSION   version, ex. 12.1.0 (défaut : dernière publiée sur GitHub)
#   MM_SITE_URL  adresse publique (défaut : http://<ip>:8065)

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

info "Mattermost - Messagerie d'équipe"

MM_VERSION="${MM_VERSION:-$(github_latest_tag mattermost/mattermost v12.1.0)}"
MM_VERSION="${MM_VERSION#v}"
MM_SITE_URL="${MM_SITE_URL:-http://$(primary_ip):8065}"
APP_DIR="/opt/mattermost"
DB_PASS="$(random_password 24)"
[ "$(dpkg --print-architecture)" = "amd64" ] || [ "$(dpkg --print-architecture)" = "arm64" ] || error_exit "Architecture non gérée"
ARCH="$(dpkg --print-architecture)"

pkg_update
pkg_install postgresql curl jq sudo
systemctl enable --now postgresql

info "Base PostgreSQL mattermost"
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='mmuser'" | grep -q 1; then
    sudo -u postgres psql -v ON_ERROR_STOP=1 <<SQL
CREATE DATABASE mattermost;
CREATE USER mmuser WITH PASSWORD '${DB_PASS}';
ALTER DATABASE mattermost OWNER TO mmuser;
\c mattermost
GRANT USAGE, CREATE ON SCHEMA public TO mmuser;
SQL
    NEW_DB=1
else
    NEW_DB=0
fi

if [ -x "${APP_DIR}/bin/mattermost" ]; then
    warn "Mattermost déjà présent dans ${APP_DIR} : archive non réinstallée (mise à jour : voir la documentation officielle)"
else
    info "Téléchargement de Mattermost ${MM_VERSION}"
    TGZ="$(mktemp --suffix=.tar.gz)"
    add_temp_file "$TGZ"
    download_file "https://releases.mattermost.com/${MM_VERSION}/mattermost-${MM_VERSION}-linux-${ARCH}.tar.gz" "$TGZ"
    tar -xzf "$TGZ" -C /opt
    mkdir -p "${APP_DIR}/data"
fi

id mattermost >/dev/null 2>&1 || useradd --system --user-group mattermost

CFG="${APP_DIR}/config/config.json"
if [ "$NEW_DB" = 1 ]; then
    backup_file "$CFG"
    tmp="$(mktemp)"
    jq --arg ds "postgres://mmuser:${DB_PASS}@localhost/mattermost?sslmode=disable&connect_timeout=10" \
       --arg url "$MM_SITE_URL" \
       '.SqlSettings.DriverName="postgres" | .SqlSettings.DataSource=$ds | .ServiceSettings.SiteURL=$url' \
       "$CFG" > "$tmp"
    mv "$tmp" "$CFG"
fi
chown -R mattermost:mattermost "$APP_DIR"
chmod -R g+w "$APP_DIR"
chmod 600 "$CFG"

cat > /etc/systemd/system/mattermost.service <<EOF
[Unit]
Description=Mattermost
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=notify
ExecStart=${APP_DIR}/bin/mattermost
TimeoutStartSec=3600
KillMode=mixed
Restart=always
RestartSec=10
WorkingDirectory=${APP_DIR}
User=mattermost
Group=mattermost
LimitNOFILE=49152

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable mattermost
systemctl restart mattermost
check_service_status mattermost
open_ports 8065/tcp

[ "$NEW_DB" = 1 ] && save_credentials /root/mattermost_identifiants.txt "Base : mattermost / utilisateur mmuser" "Mot de passe : ${DB_PASS}"

echo
echo "✅ Mattermost ${MM_VERSION} installé : ${MM_SITE_URL}"
echo "Le premier compte créé devient administrateur système : le créer sans attendre."
