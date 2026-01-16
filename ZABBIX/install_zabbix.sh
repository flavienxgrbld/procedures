#!/bin/bash
set -euo pipefail

### ==============================
### VARIABLES
### ==============================
ZABBIX_VERSION="7.4"
ZABBIX_DEB="zabbix-release_latest_${ZABBIX_VERSION}+debian13_all.deb"
ZABBIX_URL="https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/release/debian/pool/main/z/zabbix-release/${ZABBIX_DEB}"
ZABBIX_CONF="/etc/zabbix/zabbix_server.conf"

### ==============================
### FONCTIONS
### ==============================
error_exit() {
    echo "❌ ERREUR: $1" >&2
    exit 1
}

info() {
    echo "➡️  $1"
}

success() {
    echo "✅ $1"
}

### ==============================
### VÉRIFICATIONS INITIALES
### ==============================
[ "$EUID" -eq 0 ] || error_exit "Ce script doit être exécuté en root"

grep -q "trixie" /etc/os-release || error_exit "Ce script est prévu pour Debian 13 (trixie)"

info "Vérification de la connectivité HTTPS vers repo.zabbix.com"
curl -fs https://repo.zabbix.com >/dev/null || error_exit "Accès HTTPS à repo.zabbix.com impossible"

success "Environnement validé"

### ==============================
### MISE À JOUR SYSTÈME
### ==============================
info "Mise à jour du système"
apt update
apt upgrade -y

### ==============================
### INSTALLATION DÉPÔT ZABBIX
### ==============================
info "Installation du dépôt Zabbix ${ZABBIX_VERSION}"
if ! dpkg -l | grep -q zabbix-release; then
    wget -q "$ZABBIX_URL"
    dpkg -i "$ZABBIX_DEB"
else
    info "Dépôt Zabbix déjà installé"
fi

apt update

### ==============================
### INSTALLATION PAQUETS
### ==============================
info "Installation des paquets Zabbix et MariaDB"
apt install -y \
    zabbix-server-mysql \
    zabbix-frontend-php \
    zabbix-apache-conf \
    zabbix-sql-scripts \
    zabbix-agent \
    mariadb-server

success "Paquets installés"

### ==============================
### SÉCURISATION MARIADB
### ==============================
info "Sécurisation MariaDB (manuel recommandé)"
mariadb-secure-installation || true

read -sp "Mot de passe root MariaDB : " MYSQL_ROOT_PASS
echo

### ==============================
### BASE DE DONNÉES ZABBIX
### ==============================
while true; do
    read -sp "Mot de passe utilisateur SQL zabbix : " ZBX_DB_PASS
    echo
    read -sp "Confirmation : " ZBX_DB_PASS_CONFIRM
    echo
    [ "$ZBX_DB_PASS" = "$ZBX_DB_PASS_CONFIRM" ] && break
    echo "❌ Les mots de passe ne correspondent pas"
done

info "Création et configuration de la base Zabbix"
mysql -u root -p"$MYSQL_ROOT_PASS" <<EOF
CREATE DATABASE IF NOT EXISTS zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER IF NOT EXISTS zabbix@localhost IDENTIFIED BY '${ZBX_DB_PASS}';
GRANT ALL PRIVILEGES ON zabbix.* TO zabbix@localhost;
SET GLOBAL log_bin_trust_function_creators = 1;
FLUSH PRIVILEGES;
EOF

info "Import du schéma Zabbix (peut être long)"
zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | \
mysql --default-character-set=utf8mb4 -u zabbix -p"$ZBX_DB_PASS" zabbix

mysql -u root -p"$MYSQL_ROOT_PASS" -e "SET GLOBAL log_bin_trust_function_creators = 0;"

success "Base de données prête"

### ==============================
### CONFIGURATION ZABBIX
### ==============================
info "Configuration de zabbix_server.conf"

if grep -q "^DBPassword=" "$ZABBIX_CONF"; then
    sed -i "s|^DBPassword=.*|DBPassword=${ZBX_DB_PASS}|" "$ZABBIX_CONF"
else
    echo "DBPassword=${ZBX_DB_PASS}" >> "$ZABBIX_CONF"
fi

chown zabbix:zabbix "$ZABBIX_CONF"
chmod 640 "$ZABBIX_CONF"

### ==============================
### SERVICES
### ==============================
info "Redémarrage et activation des services"
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2

for svc in zabbix-server zabbix-agent apache2; do
    systemctl is-active --quiet $svc && success "$svc actif" || echo "⚠️ $svc inactif"
done

### ==============================
### TEST WEB
### ==============================
curl -fs http://localhost/zabbix >/dev/null \
    && success "Interface Web accessible" \
    || echo "⚠️ Interface Web non accessible (Apache/PHP ?)"

### ==============================
### FIN
### ==============================
echo
echo "============================================"
echo "🎉 INSTALLATION ZABBIX TERMINÉE"
echo "============================================"
echo "URL : http://IP_DU_SERVEUR/zabbix"
echo "Login : Admin"
echo "Mot de passe : zabbix"
echo "============================================"
