#!/usr/bin/env bash
# Installation de Strapi 5 en production : Node.js 22 LTS, PostgreSQL, projet créé sans
# question, interface d'administration construite, service systemd.
#
# Variables modifiables :
#   STRAPI_PROJECT  nom du projet (défaut : mon-cms)

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

info "Strapi - CMS headless"

STRAPI_PROJECT="${STRAPI_PROJECT:-mon-cms}"
APP_HOME="/opt/strapi"
PROJ="${APP_HOME}/${STRAPI_PROJECT}"
NODE_MAJOR=22

pkg_update
pkg_install curl ca-certificates gnupg postgresql build-essential sudo
if ! command -v node >/dev/null 2>&1 || [ "$(node -p 'process.versions.node.split(".")[0]')" != "$NODE_MAJOR" ]; then
    NS="$(mktemp)"; add_temp_file "$NS"
    download_file "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" "$NS"
    bash "$NS"
    pkg_install nodejs
fi
node -v
systemctl enable --now postgresql

id strapi >/dev/null 2>&1 || useradd --system --create-home --home-dir "$APP_HOME" --shell /bin/bash strapi

if [ ! -f "${PROJ}/package.json" ]; then
    DB_PASS="$(random_password 24)"
    if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='strapi'" | grep -q 1; then
        sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE USER strapi WITH PASSWORD '${DB_PASS}';"
        sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE DATABASE strapi OWNER strapi;"
    else
        sudo -u postgres psql -v ON_ERROR_STOP=1 -c "ALTER USER strapi WITH PASSWORD '${DB_PASS}';"
    fi
    info "Création du projet ${STRAPI_PROJECT} (sans question, PostgreSQL)"
    sudo -u strapi -H bash -c "cd '${APP_HOME}' && npx --yes create-strapi@latest '${STRAPI_PROJECT}' \
        --non-interactive --skip-cloud --no-run --js --use-npm --no-example --no-git-init --install \
        --dbclient=postgres --dbhost=127.0.0.1 --dbport=5432 --dbname=strapi --dbusername=strapi --dbpassword='${DB_PASS}'"
fi

info "Construction de l'interface d'administration"
sudo -u strapi -H bash -c "cd '${PROJ}' && NODE_ENV=production npm run build"

cat > /etc/systemd/system/strapi.service <<EOF
[Unit]
Description=Strapi
After=network.target postgresql.service

[Service]
User=strapi
WorkingDirectory=${PROJ}
Environment=NODE_ENV=production
ExecStart=/usr/bin/npm run start
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable strapi
systemctl restart strapi
sleep 5
check_service_status strapi
open_ports 1337/tcp

echo
echo "✅ Strapi démarré : http://$(primary_ip):1337/admin -> créer le premier administrateur sans attendre"
echo "Les types de contenus se créent en développement (npm run develop sur un poste), puis se déploient ici."
