#!/usr/bin/env bash

set -euo pipefail

# Configuration du partage SMB - modifiable directement ici
SMB_WORKGROUP="${SMB_WORKGROUP:-WORKGROUP}"
SMB_SERVER_STRING="${SMB_SERVER_STRING:-Samba Server}"
SMB_SECURITY="${SMB_SECURITY:-user}"
SMB_SHARE_NAME="${SMB_SHARE_NAME:-public}"
SMB_SHARE_PATH="${SMB_SHARE_PATH:-/srv/samba/public}"
SMB_READ_ONLY="${SMB_READ_ONLY:-no}"
SMB_GUEST_OK="${SMB_GUEST_OK:-yes}"
SMB_BROWSEABLE="${SMB_BROWSEABLE:-yes}"
SMB_CREATE_MASK="${SMB_CREATE_MASK:-0664}"
SMB_DIRECTORY_MASK="${SMB_DIRECTORY_MASK:-0775}"
SMB_FORCE_USER="${SMB_FORCE_USER:-root}"
SMB_DIR_OWNER="${SMB_DIR_OWNER:-root}"
SMB_DIR_GROUP="${SMB_DIR_GROUP:-root}"
SMB_DIR_PERMS="${SMB_DIR_PERMS:-0775}"
SMB_FILE_PERMS="${SMB_FILE_PERMS:-0664}"

prompt_value() {
    local prompt_text="$1"
    local default_value="$2"
    local variable_name="$3"
    local user_value

    if [ -t 0 ]; then
        read -r -p "${prompt_text} [${default_value}] : " user_value
        if [ -z "$user_value" ]; then
            user_value="$default_value"
        fi
    else
        user_value="$default_value"
    fi

    printf -v "$variable_name" '%s' "$user_value"
}

set_basic_config() {
    SMB_WORKGROUP="WORKGROUP"
    SMB_SERVER_STRING="Samba Server"
    SMB_SECURITY="user"
    SMB_SHARE_NAME="public"
    SMB_SHARE_PATH="/srv/samba/public"
    SMB_READ_ONLY="no"
    SMB_GUEST_OK="yes"
    SMB_BROWSEABLE="yes"
    SMB_CREATE_MASK="0664"
    SMB_DIRECTORY_MASK="0775"
    SMB_FORCE_USER="root"
    SMB_DIR_OWNER="root"
    SMB_DIR_GROUP="root"
    SMB_DIR_PERMS="0775"
    SMB_FILE_PERMS="0664"
}

set_standard_config() {
    SMB_WORKGROUP="WORKGROUP"
    SMB_SERVER_STRING="Serveur Samba"
    SMB_SECURITY="user"
    prompt_value "Nom du partage" "partages" SMB_SHARE_NAME
    prompt_value "Chemin du partage" "/srv/samba/partages" SMB_SHARE_PATH
    SMB_READ_ONLY="no"
    SMB_GUEST_OK="yes"
    SMB_BROWSEABLE="yes"
    SMB_CREATE_MASK="0664"
    SMB_DIRECTORY_MASK="0775"
    SMB_FORCE_USER="root"
    SMB_DIR_OWNER="root"
    SMB_DIR_GROUP="root"
    SMB_DIR_PERMS="0775"
    SMB_FILE_PERMS="0664"
}

set_advanced_config() {
    prompt_value "Nom du groupe de travail" "$SMB_WORKGROUP" SMB_WORKGROUP
    prompt_value "Chaîne du serveur" "$SMB_SERVER_STRING" SMB_SERVER_STRING
    prompt_value "Sécurité Samba (user/ads/etc.)" "$SMB_SECURITY" SMB_SECURITY
    prompt_value "Nom du partage" "$SMB_SHARE_NAME" SMB_SHARE_NAME
    prompt_value "Chemin du partage" "$SMB_SHARE_PATH" SMB_SHARE_PATH
    prompt_value "Lecture seule (yes/no)" "$SMB_READ_ONLY" SMB_READ_ONLY
    prompt_value "Accès invité (yes/no)" "$SMB_GUEST_OK" SMB_GUEST_OK
    prompt_value "Visible dans le réseau (yes/no)" "$SMB_BROWSEABLE" SMB_BROWSEABLE
    prompt_value "Masque de création" "$SMB_CREATE_MASK" SMB_CREATE_MASK
    prompt_value "Masque de répertoire" "$SMB_DIRECTORY_MASK" SMB_DIRECTORY_MASK
    prompt_value "Utilisateur forcé" "$SMB_FORCE_USER" SMB_FORCE_USER
    prompt_value "Propriétaire du dossier" "$SMB_DIR_OWNER" SMB_DIR_OWNER
    prompt_value "Groupe du dossier" "$SMB_DIR_GROUP" SMB_DIR_GROUP
    prompt_value "Permissions du dossier (chmod)" "$SMB_DIR_PERMS" SMB_DIR_PERMS
    prompt_value "Permissions des fichiers (chmod)" "$SMB_FILE_PERMS" SMB_FILE_PERMS
}

select_config_profile() {
    local choice

    echo "=== Niveau de configuration SMB ==="
    echo "1) Basique - partage public simple"
    echo "2) Standard - nom et chemin personnalisés"
    echo "3) Avancé - configuration détaillée"
    read -r -p "Choisissez un niveau [1] : " choice
    choice="${choice:-1}"

    case "$choice" in
        1)
            set_basic_config
            ;;
        2)
            set_standard_config
            ;;
        3)
            set_advanced_config
            ;;
        *)
            echo "Choix invalide, utilisation du mode basique."
            set_basic_config
            ;;
    esac

    echo
}

if [ -t 0 ]; then
    select_config_profile
fi

COMMON_SCRIPT="/tmp/install_common.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for candidate in \
    "$SCRIPT_DIR/../install_common.sh" \
    "$SCRIPT_DIR/../root/common/install_common.sh" \
    "$SCRIPT_DIR/../common/install_common.sh" \
    "$COMMON_SCRIPT"; do
    if [ -f "$candidate" ]; then
        COMMON_SCRIPT="$candidate"
        break
    fi
done

if [ ! -f "$COMMON_SCRIPT" ]; then
    if ! command -v curl >/dev/null 2>&1; then
        if command -v apt-get >/dev/null 2>&1; then
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -qq || true
            apt-get install -y curl || true
        fi
    fi

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/install-scripts/main/root/common/install_common.sh" -o "$COMMON_SCRIPT" || true
    fi
fi

if [ ! -f "$COMMON_SCRIPT" ]; then
    echo "❌ Impossible de charger le fichier commun d'installation. Vérifiez la connexion réseau ou créez un fichier local : $COMMON_SCRIPT"
    exit 1
fi

source "$COMMON_SCRIPT"

ensure_root
detect_os
detect_package_manager

info "Serveur SMB / Samba"

echo "=== Installation de Samba ==="

echo "Partage SMB : $SMB_SHARE_NAME"
echo "Chemin du partage : $SMB_SHARE_PATH"

case "$PKG_MANAGER" in
    apt)
        pkg_install samba samba-common
        ;;
    dnf|yum)
        pkg_install samba samba-client
        ;;
    zypper)
        pkg_install samba
        ;;
    pacman)
        pkg_install samba
        ;;
esac

mkdir -p "$SMB_SHARE_PATH"
chown "$SMB_DIR_OWNER:$SMB_DIR_GROUP" "$SMB_SHARE_PATH" 2>/dev/null || true
chmod "$SMB_DIR_PERMS" "$SMB_SHARE_PATH"

if [ -f /etc/samba/smb.conf ]; then
    cp /etc/samba/smb.conf "/etc/samba/smb.conf.bak.$(date +%Y%m%d-%H%M%S)"
fi

cat > /etc/samba/smb.conf <<EOF
[global]
   workgroup = $SMB_WORKGROUP
   server string = $SMB_SERVER_STRING
   security = $SMB_SECURITY
   map to guest = Bad User
   log file = /var/log/samba/log.%m
   max log size = 1000
   logging = file
   panic action = /usr/share/samba/panic-action %d

[$SMB_SHARE_NAME]
   path = $SMB_SHARE_PATH
   browseable = $SMB_BROWSEABLE
   read only = $SMB_READ_ONLY
   guest ok = $SMB_GUEST_OK
   create mask = $SMB_FILE_PERMS
   directory mask = $SMB_DIR_PERMS
   force user = $SMB_FORCE_USER
EOF

if command -v systemctl >/dev/null 2>&1; then
    systemctl enable --now smbd 2>/dev/null || true
    systemctl enable --now nmbd 2>/dev/null || true
    systemctl restart smbd 2>/dev/null || true
    systemctl restart nmbd 2>/dev/null || true
fi

if command -v ufw >/dev/null 2>&1; then
    ufw allow 137/tcp
    ufw allow 138/tcp
    ufw allow 139/tcp
    ufw allow 445/tcp
    ufw allow 137/udp
    ufw allow 138/udp
    ufw allow 139/udp
    ufw allow 445/udp
fi

if command -v testparm >/dev/null 2>&1; then
    testparm -s >/dev/null || true
fi

echo
printf '\n✅ Samba installé avec succès\n'
printf 'Partage configuré : %s\n' "$SMB_SHARE_NAME"
printf 'Chemin de partage : %s\n' "$SMB_SHARE_PATH"
printf 'Permissions du dossier : %s\n' "$SMB_DIR_PERMS"
printf 'Permissions des fichiers : %s\n' "$SMB_FILE_PERMS"
printf 'Fichier de config : /etc/samba/smb.conf\n'
printf 'Pour sécuriser le service, ajoutez un utilisateur Samba :\n'
printf '  sudo useradd -m monuser\n'
printf '  sudo smbpasswd -a monuser\n'
printf '\nVérification rapide :\n'
printf '  sudo systemctl status smbd\n'
printf '  sudo testparm -s\n'
printf '  smbclient -L localhost\n'
