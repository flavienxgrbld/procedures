#!/usr/bin/env bash
# Sauvegardes restic : installation, mot de passe du dépôt, initialisation,
# script de sauvegarde et minuteur systemd quotidien.
#
# Variables modifiables :
#   RESTIC_REPO   dépôt (défaut : /mnt/backup/restic ; ex. sftp:user@nas:/srv/restic, s3:https://..., rclone:gdrive:restic)
#   RESTIC_PATHS  dossiers sauvegardés (défaut : "/etc /home /root /srv")
#   RESTIC_TIME   heure de la sauvegarde (défaut : 01:30)

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

info "restic - Sauvegardes chiffrées et dédupliquées"

RESTIC_REPO="${RESTIC_REPO:-/mnt/backup/restic}"
RESTIC_PATHS="${RESTIC_PATHS:-/etc /home /root /srv}"
RESTIC_TIME="${RESTIC_TIME:-01:30}"
PASS_FILE=/etc/restic/password

pkg_update
pkg_install restic openssl
restic self-update >/dev/null 2>&1 || warn "restic self-update indisponible (paquet de la distribution conservé)"
restic version

case "$RESTIC_REPO" in
    /*)
        parent="$(dirname "$RESTIC_REPO")"
        mkdir -p "$parent"
        if ! mountpoint -q "$parent" && [ "$(df --output=source "$parent" | tail -n1)" = "$(df --output=source / | tail -n1)" ]; then
            warn "${parent} est sur le disque système : une sauvegarde doit être sur un autre disque (monter un disque à cet endroit)"
        fi
        ;;
esac

mkdir -p /etc/restic; chmod 700 /etc/restic
if [ ! -f "$PASS_FILE" ]; then
    (umask 077; openssl rand -base64 32 > "$PASS_FILE")
    NEW_PASS=1
else
    NEW_PASS=0
fi

export RESTIC_REPOSITORY="$RESTIC_REPO" RESTIC_PASSWORD_FILE="$PASS_FILE"
if restic cat config >/dev/null 2>&1; then
    info "Dépôt existant : ${RESTIC_REPO}"
else
    restic init
fi

cat > /etc/restic/backup.sh <<EOF
#!/usr/bin/env bash
set -euo pipefail
export RESTIC_REPOSITORY='${RESTIC_REPO}'
export RESTIC_PASSWORD_FILE='${PASS_FILE}'
restic backup ${RESTIC_PATHS} --exclude-caches
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune
restic check
EOF
chmod 700 /etc/restic/backup.sh

cat > /etc/systemd/system/restic-backup.service <<'EOF'
[Unit]
Description=Sauvegarde restic
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/etc/restic/backup.sh
Nice=10
IOSchedulingClass=idle
EOF
cat > /etc/systemd/system/restic-backup.timer <<EOF
[Unit]
Description=Sauvegarde restic quotidienne

[Timer]
OnCalendar=*-*-* ${RESTIC_TIME}:00
Persistent=true
RandomizedDelaySec=10min

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now restic-backup.timer

echo
echo "✅ restic configuré : dépôt ${RESTIC_REPO}, sauvegarde quotidienne à ${RESTIC_TIME}"
[ "$NEW_PASS" = 1 ] && echo "⚠️  Copier MAINTENANT le mot de passe ${PASS_FILE} en lieu sûr : sans lui, aucune restauration possible."
echo "Première sauvegarde : sudo systemctl start restic-backup.service ; journal : journalctl -u restic-backup"
