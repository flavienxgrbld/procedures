# Installation de Zabbix 7.4 sur Debian 13

## 1. Préparation du système

Passer en mode super-administrateur et mettre à jour les dépôts :

```bash
sudo su
apt update && apt upgrade -y
```

## 2. Installation du dépôt Zabbix

Téléchargement et installation du paquet du dépôt :

```bash
export PATH=$PATH:/usr/local/sbin:/usr/sbin:/sbin
wget https://repo.zabbix.com/zabbix/7.4/release/debian/pool/main/z/zabbix-release/zabbix-release_latest_7.4+debian13_all.deb
dpkg -i zabbix-release_latest_7.4+debian13_all.deb
apt update
```

## 3. Installation des dépendances

```bash
apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf \
zabbix-sql-scripts zabbix-agent mariadb-server -y

apt update && apt upgrade -y
```

## 4. Configuration de MariaDB

Lancer l’assistant de sécurisation :

```bash
mariadb-secure-installation
```

Accepter toutes les options sauf :  
**Change the root password**

### Création de la base de données Zabbix

Connexion à MariaDB :

```bash
mysql -u root -p
```

Dans MariaDB :

```sql
create database zabbix character set utf8mb4 collate utf8mb4_bin;
create user zabbix@localhost identified by 'EntreTonMotDePasse';
grant all privileges on zabbix.* to zabbix@localhost;
set global log_bin_trust_function_creators = 1;
quit;
```

### Import du schéma SQL

```bash
zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | \
mysql --default-character-set=utf8mb4 -u zabbix -p zabbix
```

Puis désactiver l’option temporaire :

```bash
mysql -u root -p
set global log_bin_trust_function_creators = 0;
quit;
```

## 5. Configuration du serveur Zabbix

Éditer le fichier de configuration :

```bash
nano /etc/zabbix/zabbix_server.conf
```

Modifier la ligne :

```
DBPassword=EntreTonMotDePasse
```

Redémarrer les services :

```bash
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2
```

## 6. Accès à l’interface Web

Ouvrir un navigateur et accéder à :

```
http://IP_DU_SERVEUR/zabbix
```

Identifiants par défaut :

- Utilisateur : Admin  
- Mot de passe : zabbix  

---

# Installation de l’agent Zabbix sur Windows

Télécharger l’agent :

```
https://cdn.zabbix.com/zabbix/binaries/stable/7.4/7.4.6/zabbix_agent2-7.4.6-windows-amd64-openssl.msi
```

Lors de l’installation, renseigner :

- l’IP du serveur Zabbix  
- le port par défaut : 10050  

---

# Ajout de l’hôte Windows dans Zabbix

Dans l’interface Zabbix :

**Collecte de données → Hôtes → Créer un hôte**

Associer le template :

```
Template OS Windows by Zabbix agent
```
