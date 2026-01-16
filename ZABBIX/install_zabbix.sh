#!/bin/bash

# Arrêter le script en cas d'erreur
set -e

# Fonction de gestion des erreurs
error_exit() {
    echo "ERREUR: $1" >&2
    echo "Le script s'est arrêté à la ligne $2" >&2
    exit 1
}

# Trappe pour capturer les erreurs
trap 'error_exit "Une erreur est survenue" $LINENO' ERR

echo "---------------------------------------------------------"
echo "Script d'installation automatisée de Zabbix 7.4 sur Debian 13"
echo "---------------------------------------------------------"

# Vérification exécution en root
if [ "$EUID" -ne 0 ]; then
    echo "ERREUR: Veuillez exécuter ce script en tant que root."
    exit 1
fi

# Vérification de la connexion Internet
echo "Vérification de la connexion Internet..."
if ! ping -c 1 repo.zabbix.com &> /dev/null; then
    error_exit "Impossible de joindre repo.zabbix.com. Vérifiez votre connexion Internet."
fi

echo "Mise à jour du système..."
apt update || error_exit "Échec de la mise à jour des paquets"
apt upgrade -y || error_exit "Échec de la mise à niveau du système"

echo "Installation du dépôt Zabbix..."
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin

if [ ! -f "zabbix-release_latest_7.4+debian13_all.deb" ]; then
    wget https://repo.zabbix.com/zabbix/7.4/release/debian/pool/main/z/zabbix-release/zabbix-release_latest_7.4+debian13_all.deb || \
        error_exit "Échec du téléchargement du paquet Zabbix"
fi

dpkg -i zabbix-release_latest_7.4+debian13_all.deb || error_exit "Échec de l'installation du dépôt Zabbix"
apt update || error_exit "Échec de la mise à jour après ajout du dépôt Zabbix"

echo "Installation des paquets Zabbix et MariaDB..."
apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf \
zabbix-sql-scripts zabbix-agent mariadb-server || \
    error_exit "Échec de l'installation des paquets Zabbix/MariaDB"

echo "Sécurisation de MariaDB (manuel)..."
echo "Lancez l'assistant et répondez OUI à tout sauf 'Change the root password'."
mariadb-secure-installation || {
    echo "AVERTISSEMENT: La sécurisation de MariaDB a échoué ou été annulée"
    read -p "Voulez-vous continuer malgré tout? (o/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        exit 1
    fi
}

echo "Création de la base de données Zabbix..."
while true; do
    read -sp "Mot de passe à définir pour l'utilisateur SQL 'zabbix' : " ZBX_DB_PASS
    echo
    if [ -z "$ZBX_DB_PASS" ]; then
        echo "ERREUR: Le mot de passe ne peut pas être vide."
        continue
    fi
    read -sp "Confirmez le mot de passe : " ZBX_DB_PASS_CONFIRM
    echo
    if [ "$ZBX_DB_PASS" = "$ZBX_DB_PASS_CONFIRM" ]; then
        break
    else
        echo "ERREUR: Les mots de passe ne correspondent pas."
    fi
done

echo "Configuration de la base de données..."
mysql -u root -p <<EOF || error_exit "Échec de la création de la base de données"
create database zabbix character set utf8mb4 collate utf8mb4_bin;
create user zabbix@localhost identified by '${ZBX_DB_PASS}';
grant all privileges on zabbix.* to zabbix@localhost;
set global log_bin_trust_function_creators = 1;
EOF

echo "Import du schéma SQL (cela peut prendre plusieurs minutes)..."
if [ ! -f "/usr/share/zabbix/sql-scripts/mysql/server.sql.gz" ]; then
    error_exit "Le fichier SQL de Zabbix est introuvable"
fi

zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | \
mysql --default-character-set=utf8mb4 -u zabbix -p${ZBX_DB_PASS} zabbix || \
    error_exit "Échec de l'import du schéma SQL"

mysql -u root -p <<EOF || error_exit "Échec de la configuration finale de la base"
set global log_bin_trust_function_creators = 0;
EOF

echo "Configuration du serveur Zabbix..."
if [ ! -f "/etc/zabbix/zabbix_server.conf" ]; then
    error_exit "Le fichier de configuration de Zabbix est introuvable"
fi

sed -i "s/# DBPassword=/DBPassword=${ZBX_DB_PASS}/" /etc/zabbix/zabbix_server.conf || \
    error_exit "Échec de la modification du fichier de configuration"

echo "Redémarrage des services..."
systemctl restart zabbix-server || error_exit "Échec du redémarrage de zabbix-server"
systemctl restart zabbix-agent || error_exit "Échec du redémarrage de zabbix-agent"
systemctl restart apache2 || error_exit "Échec du redémarrage d'apache2"

systemctl enable zabbix-server zabbix-agent apache2 || \
    error_exit "Échec de l'activation automatique des services"

# Vérification de l'état des services
echo "Vérification de l'état des services..."
for service in zabbix-server zabbix-agent apache2; do
    if systemctl is-active --quiet $service; then
        echo "✓ $service est actif"
    else
        echo "✗ AVERTISSEMENT: $service n'est pas actif"
    fi
done

echo ""
echo "============================================"
echo "Installation terminée avec succès!"
echo "============================================"
echo "Accédez à l'interface Web via : http://IP_DU_SERVEUR/zabbix"
echo "Identifiants par défaut : Admin / zabbix"
echo ""