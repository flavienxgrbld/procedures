#!/bin/bash
set -euo pipefail

ZABBIX_VERSION="7.4"
TMP_DIR="/tmp/zabbix_agent_install_$$"
AGENT_CONF=""
AGENT_SERVICE=""
PKG_MANAGER=""

error_exit() {
    echo "❌ ERREUR: $1" >&2
    cleanup
    exit 1
}

cleanup() {
    [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
}

info() {
    echo "➡️  $1"
}

success() {
    echo "✅ $1"
}

pkg_install() {
    local pkg="$1"
    case "$PKG_MANAGER" in
        apt)
            apt install -y "$pkg" ;;
        dnf)
            dnf install -y "$pkg" ;;
        yum)
            yum install -y "$pkg" ;;
        zypper)
            zypper install -y "$pkg" ;;
        pacman)
            pacman -S --noconfirm "$pkg" ;;
        *)
            return 1 ;;
    esac
}

set_config_option() {
    local key="$1"
    local value="$2"

    if grep -qE "^[[:space:]]*#?[[:space:]]*${key}=.*" "$AGENT_CONF"; then
        sed -i -E "s|^[[:space:]]*#?[[:space:]]*${key}=.*|${key}=${value}|" "$AGENT_CONF"
    else
        echo "${key}=${value}" >> "$AGENT_CONF"
    fi
}

detect_distro() {
    if [ ! -f /etc/os-release ]; then
        error_exit "Impossible de détecter la distribution (fichier /etc/os-release manquant)"
    fi

    . /etc/os-release
    OS_ID="${ID,,}"
    OS_ID_LIKE="${ID_LIKE,,}"
    VERSION_ID="${VERSION_ID%%.*}"

    if command -v apt >/dev/null; then
        PKG_MANAGER="apt"
    elif command -v dnf >/dev/null; then
        PKG_MANAGER="dnf"
    elif command -v yum >/dev/null; then
        PKG_MANAGER="yum"
    elif command -v zypper >/dev/null; then
        PKG_MANAGER="zypper"
    elif command -v pacman >/dev/null; then
        PKG_MANAGER="pacman"
    else
        error_exit "Aucun gestionnaire de paquets supporté trouvé (apt, dnf, yum, zypper, pacman)"
    fi

    info "Distribution détectée : $PRETTY_NAME"
    info "Gestionnaire de paquets : $PKG_MANAGER"
}

add_zabbix_repo() {
    case "$PKG_MANAGER" in
        apt)
            if ! command -v dpkg >/dev/null; then
                error_exit "dpkg introuvable, impossible d'installer le dépôt Zabbix"
            fi

            . /etc/os-release
            RELEASE_NAME="${ID}${VERSION_ID}"
            if [ "$OS_ID" = "ubuntu" ]; then
                RELEASE_NAME="ubuntu${VERSION_ID//./}"
            elif [ "$OS_ID" = "debian" ]; then
                RELEASE_NAME="debian${VERSION_ID}"
            fi

            ZABBIX_DEB="zabbix-release_latest_${ZABBIX_VERSION}+${RELEASE_NAME}_all.deb"
            ZABBIX_URL="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/release/debian/pool/main/z/zabbix-release/${ZABBIX_DEB}"

            if ! dpkg -l | grep -qw zabbix-release; then
                mkdir -p "$TMP_DIR"
                wget -q "$ZABBIX_URL" -O "${TMP_DIR}/${ZABBIX_DEB}" || error_exit "Téléchargement du dépôt Zabbix échoué"
                dpkg -i "${TMP_DIR}/${ZABBIX_DEB}" || error_exit "Installation du dépôt Zabbix échouée"
                apt update
            else
                info "Dépôt Zabbix déjà installé"
            fi
            ;;
        dnf|yum)
            . /etc/os-release
            if [[ "$OS_ID" =~ ^(almalinux|rocky|centos|rhel)$ ]]; then
                ZABBIX_RPM="zabbix-release-${ZABBIX_VERSION}-1.el${VERSION_ID}.noarch.rpm"
                ZABBIX_URL="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/release/rhel/${VERSION_ID}/x86_64/${ZABBIX_RPM}"
            else
                ZABBIX_RPM="zabbix-release-${ZABBIX_VERSION}-1.el${VERSION_ID}.noarch.rpm"
                ZABBIX_URL="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/release/rhel/${VERSION_ID}/x86_64/${ZABBIX_RPM}"
            fi

            if ! rpm -qa | grep -qw zabbix-release; then
                mkdir -p "$TMP_DIR"
                wget -q "$ZABBIX_URL" -O "${TMP_DIR}/${ZABBIX_RPM}" || error_exit "Téléchargement du dépôt Zabbix échoué"
                rpm -Uvh "${TMP_DIR}/${ZABBIX_RPM}" || error_exit "Installation du dépôt Zabbix échouée"
            else
                info "Dépôt Zabbix déjà installé"
            fi
            ;;
        *)
            info "Aucun dépôt officiel Zabbix ajouté pour $PKG_MANAGER. Installation depuis les dépôts de la distribution si disponible."
            ;;
    esac
}

install_agent_package() {
    local candidates=("zabbix-agent" "zabbix-agent2")
    for pkg in "${candidates[@]}"; do
        if pkg_install "$pkg"; then
            success "Package $pkg installé"
            return 0
        fi
    done

    return 1
}

detect_agent_service() {
    if [ -f /etc/zabbix/zabbix_agent2.conf ]; then
        AGENT_CONF="/etc/zabbix/zabbix_agent2.conf"
        AGENT_SERVICE="zabbix-agent2"
    else
        AGENT_CONF="/etc/zabbix/zabbix_agentd.conf"
        AGENT_SERVICE="zabbix-agent"
    fi

    if [ ! -f "$AGENT_CONF" ]; then
        error_exit "Fichier de configuration introuvable : $AGENT_CONF"
    fi
}

trap cleanup EXIT

[ "$EUID" -eq 0 ] || error_exit "Ce script doit être exécuté en root"

detect_distro

info "Installation des outils nécessaires"
case "$PKG_MANAGER" in
    apt)
        apt update
        pkg_install curl
        pkg_install wget
        pkg_install gnupg
        ;;
    dnf|yum)
        pkg_install curl
        pkg_install wget
        pkg_install gnupg2
        ;;
    zypper)
        zypper refresh
        pkg_install curl
        pkg_install wget
        pkg_install gpg2
        ;;
    pacman)
        pacman -Sy --noconfirm curl wget gnupg
        ;;
esac

info "Vérification de la connectivité"
curl -fs https://repo.zabbix.com >/dev/null || error_exit "Impossible de joindre repo.zabbix.com"

if [[ "$PKG_MANAGER" == "apt" || "$PKG_MANAGER" == "dnf" || "$PKG_MANAGER" == "yum" ]]; then
    info "Ajout du dépôt officiel Zabbix"
    add_zabbix_repo
fi

info "Installation de l'agent Zabbix"
if ! install_agent_package; then
    error_exit "Impossible d'installer le package Zabbix Agent sur cette distribution"
fi

detect_agent_service

while true; do
    read -rp "Adresse/IP du serveur Zabbix : " ZABBIX_SERVER
    [ -n "$ZABBIX_SERVER" ] && break
    echo "❌ L'adresse du serveur ne peut pas être vide"
done

read -rp "Nom d'hôte de l'agent (laisser vide pour utiliser le hostname du système) : " ZABBIX_HOSTNAME
if [ -z "$ZABBIX_HOSTNAME" ]; then
    ZABBIX_HOSTNAME="$(hostname -f 2>/dev/null || hostname)"
fi

info "Configuration de l'agent Zabbix"
set_config_option "Server" "$ZABBIX_SERVER"
set_config_option "ServerActive" "$ZABBIX_SERVER"
set_config_option "Hostname" "$ZABBIX_HOSTNAME"

chown zabbix:zabbix "$AGENT_CONF" || true
chmod 640 "$AGENT_CONF" || true

info "Activation et démarrage du service"
systemctl enable "$AGENT_SERVICE"
systemctl restart "$AGENT_SERVICE"

if systemctl is-active --quiet "$AGENT_SERVICE"; then
    success "Agent Zabbix démarré et actif"
else
    error_exit "Le service $AGENT_SERVICE n'a pas démarré correctement"
fi

echo
cat <<EOF
========================================
Agent Zabbix installé avec succès
Serveur Zabbix : $ZABBIX_SERVER
Hostname agent : $ZABBIX_HOSTNAME
Fichier de configuration : $AGENT_CONF
EOF
