#!/usr/bin/env bash
# Installation de Node-RED avec le script officiel (Node.js LTS + Node-RED + service nodered),
# sous un utilisateur non root, avec l'authentification de l'éditeur activée.
#
# Variables modifiables :
#   NODERED_USER        utilisateur du service (défaut : celui qui a lancé sudo)
#   NODERED_ADMIN_PASS  mot de passe du compte admin de l'éditeur (défaut : généré)

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

info "Node-RED - Programmation visuelle par flux"

NODERED_USER="${NODERED_USER:-${SUDO_USER:-}}"
[ -n "$NODERED_USER" ] && [ "$NODERED_USER" != "root" ] && id "$NODERED_USER" >/dev/null 2>&1 \
    || error_exit "Lancer avec sudo depuis un compte utilisateur, ou définir NODERED_USER (pas root)"
USER_HOME="$(getent passwd "$NODERED_USER" | cut -d: -f6)"
NODERED_ADMIN_PASS="${NODERED_ADMIN_PASS:-$(random_password 16)}"

pkg_update
pkg_install build-essential git curl sudo

INSTALLER="$(mktemp)"
add_temp_file "$INSTALLER"
download_file https://github.com/node-red/linux-installers/releases/latest/download/install-update-nodered-deb "$INSTALLER"
chmod 755 "$INSTALLER"
info "Script officiel (service nodered sous ${NODERED_USER}, sans question)"
bash "$INSTALLER" --confirm-root --confirm-install --skip-pi --nodered-user="$NODERED_USER"

SETTINGS="${USER_HOME}/.node-red/settings.js"
if [ ! -f "$SETTINGS" ]; then
    sudo -u "$NODERED_USER" -H node-red admin init >/dev/null 2>&1 || true
fi
[ -f "$SETTINGS" ] || error_exit "settings.js introuvable : lancer une fois « node-red » sous ${NODERED_USER}"

if grep -qE '^\s*adminAuth:' "$SETTINGS"; then
    warn "adminAuth déjà configuré dans settings.js : compte inchangé"
    NEW_PASS=0
else
    info "Activation de l'authentification de l'éditeur"
    # Hash bcrypt calculé avec la bibliothèque fournie par Node-RED (node-red admin hash-pw est interactif)
    HASH="$(node -e '
const r = require("module").createRequire(process.argv[2] + "/node-red/package.json");
let b; for (const m of ["bcryptjs", "@node-red/util/node_modules/bcryptjs", "bcrypt"]) { try { b = r(m); break; } catch (e) {} }
if (!b) process.exit(1);
console.log(b.hashSync(process.argv[1], 8));' "$NODERED_ADMIN_PASS" "$(npm root -g)")" || true
    [[ "$HASH" == \$2* ]] || error_exit "Impossible de générer le hash du mot de passe"
    python3 - "$SETTINGS" "$HASH" <<'PY'
import sys
path, h = sys.argv[1], sys.argv[2]
s = open(path).read()
block = ('    adminAuth: {\n        type: "credentials",\n        users: [{\n            username: "admin",\n'
         f'            password: "{h}",\n            permissions: "*"\n        }}]\n    }},\n')
s = s.replace("module.exports = {\n", "module.exports = {\n" + block, 1)
open(path, "w").write(s)
PY
    NEW_PASS=1
fi

systemctl enable nodered
systemctl restart nodered
check_service_status nodered
open_ports 1880/tcp
[ "$NEW_PASS" = 1 ] && save_credentials /root/nodered_identifiants.txt "Éditeur Node-RED : admin" "Mot de passe : ${NODERED_ADMIN_PASS}"

echo
echo "✅ Node-RED installé (service nodered sous ${NODERED_USER}) : http://$(primary_ip):1880"
