#!/usr/bin/env bash
# Installation de File Browser (binaire officiel) en service systemd, sous un
# utilisateur dédié, limité au dossier partagé.
#
# Variables modifiables :
#   FB_ROOT        dossier partagé (défaut : /srv/partage)
#   FB_PORT        port d'écoute (défaut : 8080)
#   FB_ADMIN_PASS  mot de passe du compte admin (défaut : généré, 12 caractères minimum)

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

info "File Browser - Gestionnaire de fichiers web"
command -v systemctl >/dev/null 2>&1 || error_exit "systemd est requis"

FB_ROOT="${FB_ROOT:-/srv/partage}"
FB_PORT="${FB_PORT:-8080}"
FB_ADMIN_PASS="${FB_ADMIN_PASS:-$(random_password 16)}"
[ "${#FB_ADMIN_PASS}" -ge 12 ] || error_exit "FB_ADMIN_PASS doit faire au moins 12 caractères"
DB="/var/lib/filebrowser/filebrowser.db"

pkg_install curl tar

info "Installation du binaire officiel (script get.sh)"
GET_SH="$(mktemp)"
add_temp_file "$GET_SH"
download_file https://raw.githubusercontent.com/filebrowser/get/master/get.sh "$GET_SH"
bash "$GET_SH"
FB_BIN="$(command -v filebrowser)"
"$FB_BIN" version

if ! id filebrowser >/dev/null 2>&1; then
    useradd --system --no-create-home --shell /usr/sbin/nologin filebrowser
fi
mkdir -p /var/lib/filebrowser "$FB_ROOT"
chown filebrowser:filebrowser /var/lib/filebrowser
chown filebrowser:filebrowser "$FB_ROOT"

fb() { sudo -u filebrowser "$FB_BIN" -d "$DB" "$@"; }
pkg_install sudo

if [ ! -f "$DB" ]; then
    info "Initialisation de la base et du compte admin"
    fb config init >/dev/null
    fb users add admin "$FB_ADMIN_PASS" --perm.admin >/dev/null
    NEW_ADMIN=1
else
    info "Base existante conservée : ${DB}"
    NEW_ADMIN=0
fi
fb config set --address 0.0.0.0 --port "$FB_PORT" --root "$FB_ROOT" --log stdout >/dev/null

cat > /etc/systemd/system/filebrowser.service <<EOF
[Unit]
Description=File Browser
After=network.target

[Service]
User=filebrowser
Group=filebrowser
ExecStart=${FB_BIN} -d ${DB}
Restart=on-failure
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths=/var/lib/filebrowser ${FB_ROOT}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable filebrowser
systemctl restart filebrowser
sleep 2
check_service_status filebrowser
open_ports "${FB_PORT}/tcp"

if [ "$NEW_ADMIN" = 1 ]; then
    save_credentials /root/filebrowser_identifiants.txt "Compte : admin" "Mot de passe : ${FB_ADMIN_PASS}"
fi

echo
echo "✅ File Browser installé : http://$(hostname -I | awk '{print $1}'):${FB_PORT}"
echo "Dossier partagé : ${FB_ROOT}"
[ "$NEW_ADMIN" = 1 ] && echo "Compte admin : /root/filebrowser_identifiants.txt"
exit 0
