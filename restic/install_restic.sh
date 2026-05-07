#!/usr/bin/env bash

set -euo pipefail

COMMON_SCRIPT="/tmp/install_common.sh"
if [ ! -f "$COMMON_SCRIPT" ]; then
    curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/install-scripts/main/root/common/install_common.sh" -o "$COMMON_SCRIPT"
fi
source "$COMMON_SCRIPT"

ensure_root
detect_os
detect_package_manager

info "Restic - Backup décentralisé et sécurisé"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

echo "=== Installation de Restic ==="
case "$PKG_MANAGER" in
    apt)
        pkg_install restic
        ;;
    dnf|yum)
        pkg_install restic
        ;;
    zypper)
        pkg_install restic
        ;;
    pacman)
        pkg_install restic
        ;;
esac

# Création répertoire de configuration
mkdir -p /etc/restic

# Configuration de base
cat > /etc/restic/backup.conf <<'EOF'
#!/bin/bash
BACKUP_DIRS="/home /etc /root"
RESTIC_REPO="/mnt/backup/restic"
RESTIC_PASSWORD_FILE="/etc/restic/password"
RESTIC_FORGET_KEEP="--keep-daily 7 --keep-weekly 4 --keep-monthly 12"
EOF

chmod 600 /etc/restic/backup.conf

# Script de backup
cat > /etc/restic/backup.sh <<'EOF'
#!/bin/bash
source /etc/restic/backup.conf

# Initialiser le dépôt si nécessaire
restic -r $RESTIC_REPO init || true

# Effectuer le backup
restic -r $RESTIC_REPO backup $BACKUP_DIRS

# Nettoyer les anciennes sauvegardes
restic -r $RESTIC_REPO forget $RESTIC_FORGET_KEEP --prune

# Vérifier intégrité
restic -r $RESTIC_REPO check
EOF

chmod +x /etc/restic/backup.sh

# Tâche cron pour backups automatiques
cat > /etc/cron.d/restic <<EOF
0 2 * * * root /etc/restic/backup.sh >> /var/log/restic.log 2>&1
EOF

echo
echo "✅ Restic installé avec succès"
echo "Configuration: /etc/restic/backup.conf"
echo "Script backup: /etc/restic/backup.sh"
echo "À faire:"
echo "  1. Définir le mot de passe dans /etc/restic/password"
echo "  2. Configurer les chemins de sauvegarde"
echo "  3. Initialiser le dépôt: /etc/restic/backup.sh"
