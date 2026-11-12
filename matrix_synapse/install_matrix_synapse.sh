#!/usr/bin/env bash
# Installation de Synapse (serveur Matrix) depuis le dépôt officiel, avec PostgreSQL.
#
# Variables :
#   MATRIX_SERVER_NAME  nom du serveur, ex. matrix.exemple.fr (obligatoire, définitif)
#   MATRIX_EMAIL        e-mail Let's Encrypt : publie aussi Synapse derrière Nginx en HTTPS (facultatif)

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

info "Synapse - Serveur Matrix"

[ -n "${MATRIX_SERVER_NAME:-}" ] || error_exit "Définir MATRIX_SERVER_NAME (ex. matrix.exemple.fr) : il fait partie des identifiants et ne peut plus changer"
CONF=/etc/matrix-synapse/homeserver.yaml
DB_PASS="$(random_password 24)"

pkg_update
pkg_install lsb-release wget curl apt-transport-https ca-certificates debconf-utils postgresql
download_file https://packages.matrix.org/debian/matrix-org-archive-keyring.gpg /usr/share/keyrings/matrix-org-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/matrix-org-archive-keyring.gpg] https://packages.matrix.org/debian/ $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/matrix-org.list
pkg_update

debconf-set-selections <<EOF
matrix-synapse-py3 matrix-synapse/server-name string ${MATRIX_SERVER_NAME}
matrix-synapse-py3 matrix-synapse/report-stats boolean false
EOF
pkg_install matrix-synapse-py3

info "Base PostgreSQL synapse"
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='synapse_user'" | grep -q 1; then
    sudo -u postgres psql -c "CREATE USER synapse_user WITH PASSWORD '${DB_PASS}';"
    sudo -u postgres createdb --encoding=UTF8 --locale=C --template=template0 --owner=synapse_user synapse
    NEW_DB=1
else
    NEW_DB=0
    warn "Utilisateur PostgreSQL synapse_user existant : configuration de la base conservée"
fi

if [ "$NEW_DB" = 1 ]; then
    backup_file "$CONF"
    python3 - "$CONF" "$DB_PASS" "$(random_password 48)" <<'PY'
import re, sys
path, pwd, secret = sys.argv[1:4]
s = open(path).read()
db = f"""database:
  name: psycopg2
  args:
    user: synapse_user
    password: {pwd}
    dbname: synapse
    host: localhost
    cp_min: 5
    cp_max: 10
"""
s = re.sub(r'^database:\n(?:[ \t]+.*\n?)*', db, s, flags=re.M) if re.search(r'^database:', s, re.M) else s + "\n" + db
if not re.search(r'^registration_shared_secret:', s, re.M):
    s += f'\nregistration_shared_secret: "{secret}"\n'
open(path, 'w').write(s)
PY
    chown root:matrix-synapse "$CONF"
    chmod 640 "$CONF"
fi

systemctl enable matrix-synapse
systemctl restart matrix-synapse
sleep 3
check_service_status matrix-synapse

if [ -n "${MATRIX_EMAIL:-}" ]; then
    info "Nginx + Let's Encrypt pour ${MATRIX_SERVER_NAME}"
    pkg_install nginx certbot python3-certbot-nginx
    cat > /etc/nginx/sites-available/matrix <<EOF
server {
    listen 80;
    listen 8448;
    server_name ${MATRIX_SERVER_NAME};

    location ~ ^(/_matrix|/_synapse/client) {
        proxy_pass http://127.0.0.1:8008;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Host \$host;
        client_max_body_size 50M;
        proxy_http_version 1.1;
    }
}
EOF
    ln -sf /etc/nginx/sites-available/matrix /etc/nginx/sites-enabled/matrix
    nginx -t && systemctl reload nginx
    certbot --nginx -d "$MATRIX_SERVER_NAME" -m "$MATRIX_EMAIL" --agree-tos --non-interactive --redirect
    # certbot ne gère que le port 443 : le port de fédération 8448 passe aussi en TLS
    sed -i 's/^\(\s*\)listen 8448;/\1listen 8448 ssl;/' /etc/nginx/sites-available/matrix
    nginx -t && systemctl reload nginx
    open_ports 80/tcp 443/tcp 8448/tcp
fi

[ "$NEW_DB" = 1 ] && save_credentials /root/synapse_identifiants.txt "Base : synapse / utilisateur synapse_user" "Mot de passe : ${DB_PASS}"

echo
echo "✅ Synapse installé pour ${MATRIX_SERVER_NAME}"
echo "Créer le compte administrateur :"
echo "  sudo register_new_matrix_user -c ${CONF} http://localhost:8008"
