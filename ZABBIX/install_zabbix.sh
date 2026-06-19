#!/bin/bash
set -euo pipefail

# Variables de configuration
ZABBIX_VERSION="7.4"
ZABBIX_CONF="/etc/zabbix/zabbix_server.conf"
TMP_DIR="/tmp/zabbix_install_$$"
PKG_MANAGER=""
OS_ID=""
OS_ID_LIKE=""
VERSION_ID=""


error_exit() {
    echo "❌ ERREUR: $1" >&2
    cleanup
    exit 1
}

cleanup() {
    [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
    unset MYSQL_ROOT_PASS ZBX_DB_PASS ZBX_DB_PASS_CONFIRM 2>/dev/null || true
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
            zypper install -yn "$pkg" ;;
        pacman)
            pacman -S --noconfirm "$pkg" ;;
        *)
            return 1 ;;
    esac
}

pkg_update() {
    case "$PKG_MANAGER" in
        apt)
            apt update ;;
        dnf)
            dnf makecache ;;
        yum)
            yum makecache ;;
        zypper)
            zypper refresh ;;
        pacman)
            pacman -Sy ;;
        *)
            return 1 ;;
    esac
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
            if [ "$OS_ID" = "ubuntu" ]; then
                RELEASE_NAME="ubuntu${VERSION_ID//./}"
            elif [ "$OS_ID" = "debian" ]; then
                RELEASE_NAME="debian${VERSION_ID}"
            else
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
            if [ "$OS_ID" = "fedora" ]; then
                ZABBIX_RPM="zabbix-release-${ZABBIX_VERSION}-1.fc${VERSION_ID}.noarch.rpm"
                ZABBIX_URL="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/release/fedora/${VERSION_ID}/x86_64/${ZABBIX_RPM}"
            elif [[ "$OS_ID" =~ ^(almalinux|rocky|centos|rhel)$ ]]; then
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
        zypper)
            . /etc/os-release
            ZABBIX_RPM="zabbix-release-${ZABBIX_VERSION}-1.sles${VERSION_ID}.noarch.rpm"
            ZABBIX_URL="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/release/sles/${VERSION_ID}/x86_64/${ZABBIX_RPM}"

            if ! rpm -qa | grep -qw zabbix-release; then
                mkdir -p "$TMP_DIR"
                wget -q "$ZABBIX_URL" -O "${TMP_DIR}/${ZABBIX_RPM}" || error_exit "Téléchargement du dépôt Zabbix échoué"
                rpm -Uvh "${TMP_DIR}/${ZABBIX_RPM}" || error_exit "Installation du dépôt Zabbix échouée"
                zypper refresh
            else
                info "Dépôt Zabbix déjà installé"
            fi
            ;;
        pacman)
            info "Aucun dépôt officiel Zabbix ajouté pour pacman. Installation depuis les dépôts de la distribution si disponible."
            ;;
        *)
            info "Aucun dépôt Zabbix ajouté pour ce gestionnaire de paquets"
            ;;
    esac
}

install_zabbix_packages() {
    case "$PKG_MANAGER" in
        apt)
            pkg_install zabbix-server-mysql
            pkg_install zabbix-frontend-php
            pkg_install zabbix-apache-conf
            pkg_install zabbix-sql-scripts
            pkg_install zabbix-agent
            pkg_install mariadb-server
            ;;
        dnf|yum)
            pkg_install zabbix-server-mysql
            pkg_install zabbix-web-mysql
            pkg_install zabbix-apache-conf
            pkg_install zabbix-sql-scripts
            pkg_install zabbix-agent
            pkg_install mariadb-server
            ;;
        zypper)
            pkg_install zabbix-server-mysql
            pkg_install zabbix-web-mysql
            pkg_install zabbix-apache-conf
            pkg_install zabbix-sql-scripts
            pkg_install zabbix-agent
            pkg_install mariadb
            ;;
        pacman)
            error_exit "Installation du serveur Zabbix non supportée pour pacman. Utilisez une distribution DEB/RPM/SUSE ou installez manuellement."
            ;;
        *)
            error_exit "Installation non supportée pour le gestionnaire de paquets : $PKG_MANAGER"
            ;;
    esac
}

trap cleanup EXIT


[ "$EUID" -eq 0 ] || error_exit "Ce script doit être exécuté en root"

detect_distro

info "Installation des outils nécessaires"
pkg_update
case "$PKG_MANAGER" in
    apt)
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
        pkg_install curl
        pkg_install wget
        pkg_install gpg2
        ;;
    pacman)
        pkg_install curl
        pkg_install wget
        pkg_install gnupg
        ;;
    *)
        error_exit "Gestionnaire de paquets non pris en charge : $PKG_MANAGER"
        ;;
esac
info "Vérification de la connectivité HTTPS vers repo.zabbix.com"
curl -fs https://repo.zabbix.com >/dev/null || error_exit "Accès HTTPS à repo.zabbix.com impossible"

success "Environnement validé"


info "Mise à jour du système"
pkg_update
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin





info "Installation du dépôt Zabbix ${ZABBIX_VERSION}"
add_zabbix_repo


info "Installation des paquets Zabbix et MariaDB"
install_zabbix_packages

success "Paquets installés"


info "Sécurisation automatique de MariaDB"
read -sp "Mot de passe root MariaDB à définir : " MYSQL_ROOT_PASS
echo

# Sécurisation automatique de MySQL
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';" 2>/dev/null || \
    mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MYSQL_ROOT_PASS}');"

mysql -u root -p"$MYSQL_ROOT_PASS" <<EOSQL
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOSQL

success "MariaDB sécurisé automatiquement"

# Validation de la connexion MySQL
if ! mysql -u root -p"$MYSQL_ROOT_PASS" -e "SELECT 1;" &>/dev/null; then
    error_exit "Impossible de se connecter à MariaDB avec ce mot de passe"
fi

while true; do
    read -sp "Mot de passe utilisateur SQL zabbix : " ZBX_DB_PASS
    echo
    [ -n "$ZBX_DB_PASS" ] || { echo "❌ Le mot de passe ne peut pas être vide"; continue; }
    read -sp "Confirmation : " ZBX_DB_PASS_CONFIRM
    echo
    [ "$ZBX_DB_PASS" = "$ZBX_DB_PASS_CONFIRM" ] && break
    echo "❌ Les mots de passe ne correspondent pas"
done

info "Création et configuration de la base Zabbix"
mysql -u root -p"$MYSQL_ROOT_PASS" <<EOF || error_exit "Échec de la création de la base de données"
CREATE DATABASE IF NOT EXISTS zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER IF NOT EXISTS 'zabbix'@'localhost' IDENTIFIED BY '${ZBX_DB_PASS}';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
FLUSH PRIVILEGES;
EOF

info "Import du schéma Zabbix (peut être long)"
if zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | \
   mysql --default-character-set=utf8mb4 -u zabbix -p"$ZBX_DB_PASS" zabbix; then
    mysql -u root -p"$MYSQL_ROOT_PASS" -e "SET GLOBAL log_bin_trust_function_creators = 0;" || true
    success "Base de données prête"
else
    error_exit "Échec de l'import du schéma Zabbix"
fi


info "Configuration de zabbix_server.conf"

if grep -q "^DBPassword=" "$ZABBIX_CONF"; then
    sed -i "s|^DBPassword=.*|DBPassword=${ZBX_DB_PASS}|" "$ZABBIX_CONF"
else
    echo "DBPassword=${ZBX_DB_PASS}" >> "$ZABBIX_CONF"
fi

chown zabbix:zabbix "$ZABBIX_CONF"
chmod 640 "$ZABBIX_CONF"

info "Redémarrage et activation des services"
systemctl enable zabbix-server zabbix-agent apache2

SERVICES_OK=true
for svc in zabbix-server zabbix-agent apache2; do
    if systemctl restart "$svc" && systemctl is-active --quiet "$svc"; then
        success "$svc actif"
    else
        echo "⚠️ $svc inactif ou échec du redémarrage"
        SERVICES_OK=false
    fi
done

[ "$SERVICES_OK" = true ] || error_exit "Certains services ont échoué"

info "Vérification de l'interface Web (attente 5 secondes)"
sleep 5
if curl -fs http://localhost/zabbix >/dev/null; then
    success "Interface Web accessible"
else
    echo "⚠️ Interface Web non accessible - vérifier Apache/PHP"
fi


echo
echo "============================================"
echo "🎉 INSTALLATION ZABBIX TERMINÉE"
echo "============================================"
echo "URL : http://IP_DU_SERVEUR/zabbix"
echo "Login : Admin"
echo "Mot de passe : zabbix"
echo "============================================"
