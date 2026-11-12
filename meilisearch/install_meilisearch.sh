#!/usr/bin/env bash
# Installation de Meilisearch (binaire officiel) en service systemd, en mode
# production avec une clé maîtresse.
#
# Variables modifiables :
#   MEILI_MASTER_KEY  clé maîtresse (défaut : générée, 32 caractères minimum)
#   MEILI_LISTEN      127.0.0.1 (défaut, accès local) ou 0.0.0.0 (accès réseau)

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

info "Meilisearch - Moteur de recherche"
command -v systemctl >/dev/null 2>&1 || error_exit "systemd est requis"

MEILI_LISTEN="${MEILI_LISTEN:-127.0.0.1}"
CONF=/etc/meilisearch.toml

pkg_install curl
WORK="$(mktemp -d)"
add_temp_file "$WORK"
INSTALLER="${WORK}/install.sh"
download_file https://install.meilisearch.com "$INSTALLER"
(cd "$WORK" && sh "$INSTALLER")
install -m 0755 "${WORK}/meilisearch" /usr/local/bin/meilisearch
/usr/local/bin/meilisearch --version

id meilisearch >/dev/null 2>&1 || useradd --system --home-dir /var/lib/meilisearch --shell /usr/sbin/nologin meilisearch
mkdir -p /var/lib/meilisearch/{data,dumps,snapshots}
chown -R meilisearch:meilisearch /var/lib/meilisearch

if [ -f "$CONF" ]; then
    info "Configuration existante conservée : ${CONF}"
    MEILI_MASTER_KEY="$(sed -nE 's/^master_key *= *"([^"]+)".*/\1/p' "$CONF")"
else
    MEILI_MASTER_KEY="${MEILI_MASTER_KEY:-$(random_password 40)}"
    [ "${#MEILI_MASTER_KEY}" -ge 16 ] || error_exit "La clé maîtresse doit faire au moins 16 caractères"
    cat > "$CONF" <<EOF
env = "production"
master_key = "${MEILI_MASTER_KEY}"
db_path = "/var/lib/meilisearch/data"
dump_dir = "/var/lib/meilisearch/dumps"
snapshot_dir = "/var/lib/meilisearch/snapshots"
http_addr = "${MEILI_LISTEN}:7700"
EOF
fi
chown root:meilisearch "$CONF"
chmod 640 "$CONF"

cat > /etc/systemd/system/meilisearch.service <<'EOF'
[Unit]
Description=Meilisearch
After=network.target

[Service]
Type=simple
User=meilisearch
Group=meilisearch
WorkingDirectory=/var/lib/meilisearch
ExecStart=/usr/local/bin/meilisearch --config-file-path /etc/meilisearch.toml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable meilisearch
systemctl restart meilisearch
check_service_status meilisearch
[ "$MEILI_LISTEN" = "127.0.0.1" ] || open_ports 7700/tcp

save_credentials /root/meilisearch_identifiants.txt "API : http://${MEILI_LISTEN}:7700" "Clé maîtresse : ${MEILI_MASTER_KEY}"

echo
echo "✅ Meilisearch installé (écoute ${MEILI_LISTEN}:7700, clé maîtresse dans /root/meilisearch_identifiants.txt)"
echo "Test : curl -H \"Authorization: Bearer <clé>\" http://127.0.0.1:7700/keys"
