#!/bin/bash
set -euo pipefail

# Variables de configuration
ZABBIX_VERSION="7.4"
ZABBIX_DEB="zabbix-release_latest_${ZABBIX_VERSION}+debian13_all.deb"
ZABBIX_URL="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/release/debian/pool/main/z/zabbix-release/${ZABBIX_DEB}"
ZABBIX_CONF="/etc/zabbix/zabbix_server.conf"
TMP_DIR="/tmp/zabbix_install_$$"


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

trap cleanup EXIT


[ "$EUID" -eq 0 ] || error_exit "Ce script doit être exécuté en root"

grep -q "trixie" /etc/os-release || error_exit "Ce script est prévu pour Debian 13 (trixie)"
info "Installation des outils nécessaires"
apt install curl wget -y
info "Vérification de la connectivité HTTPS vers repo.zabbix.com"
curl -fs https://repo.zabbix.com >/dev/null || error_exit "Accès HTTPS à repo.zabbix.com impossible"

success "Environnement validé"


info "Mise à jour du système"
apt update
apt upgrade -y
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin





info "Installation du dépôt Zabbix ${ZABBIX_VERSION}"
if ! dpkg -l | grep -q zabbix-release; then
    mkdir -p "$TMP_DIR"
    wget -q "$ZABBIX_URL" -O "${TMP_DIR}/${ZABBIX_DEB}"
    dpkg -i "${TMP_DIR}/${ZABBIX_DEB}"
    apt update
else
    info "Dépôt Zabbix déjà installé"
fi


info "Installation des paquets Zabbix et MariaDB"
apt install -y \
    zabbix-server-mysql \
    zabbix-frontend-php \
    zabbix-apache-conf \
    zabbix-sql-scripts \
    zabbix-agent \
    mariadb-server

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
