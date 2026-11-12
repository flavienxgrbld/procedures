#!/usr/bin/env bash
# Synchronisation nocturne d'un dossier local vers un bucket Backblaze B2 avec rclone.
#
# Variables obligatoires :
#   B2_KEY_ID     keyID de la clé d'application Backblaze
#   B2_APP_KEY    applicationKey
#   B2_BUCKET     nom du bucket (déjà créé dans la console Backblaze)
#   SOURCE_DIR    dossier local à sauvegarder
# Variables facultatives :
#   B2_PATH       sous-dossier dans le bucket (défaut : nom de la machine)
#   RCLONE_MODE   sync (miroir, supprime à destination) ou copy (défaut : sync)
#   SYNC_TIME     heure du lancement quotidien (défaut : 02:00)
#
# Exemple :
#   sudo B2_KEY_ID=xxx B2_APP_KEY=yyy B2_BUCKET=mon-bucket SOURCE_DIR=/srv/donnees \
#        bash install_backblaze_sync.sh

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

info "Backblaze B2 - Synchronisation avec rclone"

missing=()
for v in B2_KEY_ID B2_APP_KEY B2_BUCKET SOURCE_DIR; do
    [ -n "${!v:-}" ] || missing+=("$v")
done
if [ ${#missing[@]} -gt 0 ]; then
    error_exit "Variables manquantes : ${missing[*]} (voir l'en-tête du script ou le README)"
fi
[ -d "$SOURCE_DIR" ] || error_exit "Le dossier source n'existe pas : $SOURCE_DIR"

B2_PATH="${B2_PATH:-$(hostname -s)}"
RCLONE_MODE="${RCLONE_MODE:-sync}"
SYNC_TIME="${SYNC_TIME:-02:00}"
case "$RCLONE_MODE" in sync|copy) ;; *) error_exit "RCLONE_MODE doit valoir sync ou copy" ;; esac

DEST="b2:${B2_BUCKET}/${B2_PATH}"
RCLONE_CONF="/root/.config/rclone/rclone.conf"

info "Installation de rclone"
pkg_update
pkg_install rclone
rclone version | head -n1

info "Déclaration du stockage b2 dans ${RCLONE_CONF}"
mkdir -p "$(dirname "$RCLONE_CONF")"
if [ -f "$RCLONE_CONF" ] && grep -q '^\[b2\]' "$RCLONE_CONF"; then
    backup_file "$RCLONE_CONF"
    rclone config delete b2 --config "$RCLONE_CONF"
fi
(umask 077; cat >> "$RCLONE_CONF") <<EOF
[b2]
type = b2
account = ${B2_KEY_ID}
key = ${B2_APP_KEY}
hard_delete = false
EOF
chmod 600 "$RCLONE_CONF"

info "Test de l'accès au bucket ${B2_BUCKET}"
rclone lsf "b2:${B2_BUCKET}" --max-depth 1 --config "$RCLONE_CONF" >/dev/null \
    || error_exit "Accès au bucket impossible : vérifier la clé, ses droits et le nom du bucket"

info "Simulation (--dry-run) de la première synchronisation"
rclone "$RCLONE_MODE" "$SOURCE_DIR" "$DEST" --dry-run --config "$RCLONE_CONF" --stats-one-line -v 2>&1 | tail -n 5

info "Création du service et du minuteur systemd (${SYNC_TIME} chaque jour)"
cat > /etc/systemd/system/backblaze-sync.service <<EOF
[Unit]
Description=Synchronisation de ${SOURCE_DIR} vers ${DEST}
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/rclone ${RCLONE_MODE} ${SOURCE_DIR} ${DEST} --config ${RCLONE_CONF} --log-file=/var/log/rclone-b2.log --log-level INFO
Nice=10
IOSchedulingClass=idle
EOF

cat > /etc/systemd/system/backblaze-sync.timer <<EOF
[Unit]
Description=Lancement quotidien de backblaze-sync

[Timer]
OnCalendar=*-*-* ${SYNC_TIME}:00
Persistent=true
RandomizedDelaySec=10min

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now backblaze-sync.timer

echo
echo "✅ Synchronisation configurée : ${SOURCE_DIR} -> ${DEST} (${RCLONE_MODE})"
echo "Prochain lancement : $(systemctl list-timers backblaze-sync.timer --no-legend | awk '{print $1, $2, $3}')"
echo "Lancer maintenant  : sudo systemctl start backblaze-sync.service"
echo "Journal            : /var/log/rclone-b2.log"
