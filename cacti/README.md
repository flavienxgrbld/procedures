# Installation de Cacti

## Description
Cacti est un outil de supervision qui permet de collecter, stocker et afficher des données sous forme de graphiques. Il s'appuie généralement sur RRDTool et SNMP pour la collecte de données.

## Prérequis
- Système d'exploitation : Ubuntu/Debian Linux (ou autre distribution compatible)
- Accès : root ou sudo
- Connexion Internet
- Serveur web (Apache recommandé)
- Base de données (MySQL/MariaDB)
- PHP

## Installation

### Méthode automatique (recommandée)

```bash
bash install_cacti.sh
```

### Installation manuelle (étapes détaillées)

#### 1. Mise à jour du système
```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. Installation des dépendances
```bash
sudo apt install apache2 mariadb-server php php-mysql php-snmp php-xml php-gd php-mbstring php-ldap rrdtool snmp snmpd git -y
```

#### 3. Sécurisation de la base de données
```bash
sudo mysql_secure_installation
```

#### 4. Création de la base de données
```bash
sudo mysql -u root -p
```

Dans le shell MySQL :
```sql
CREATE DATABASE cacti;
CREATE USER 'cacti'@'localhost' IDENTIFIED BY 'motdepasse';
GRANT ALL PRIVILEGES ON cacti.* TO 'cacti'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

#### 5. Téléchargement de Cacti
```bash
cd /var/www/html
sudo git clone https://github.com/Cacti/cacti.git
sudo mv cacti cacti-site
```

#### 6. Configuration
```bash
cd cacti-site
cp include/config.php.dist include/config.php
nano include/config.php
```

Modifier les paramètres de base de données :
```
$database_type     = 'mysql';
$database_default  = 'cacti';
$database_hostname = 'localhost';
$database_username = 'cacti';
$database_password = 'motdepasse';
```

#### 7. Permissions
```bash
sudo chown -R www-data:www-data /var/www/html/cacti-site
sudo chmod -R 775 /var/www/html/cacti-site
```

#### 8. Configuration Apache
```bash
sudo nano /etc/apache2/sites-available/cacti.conf
```

Contenu :
```
<VirtualHost *:80>
    ServerName votre-domaine.com
    DocumentRoot /var/www/html/cacti-site

    <Directory /var/www/html/cacti-site>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

Activation :
```bash
sudo a2enmod rewrite
sudo a2ensite cacti.conf
sudo systemctl reload apache2
```

## Configuration

### Finalisation via interface web
1. Accédez à : `http://votre-serveur/cacti-site`
2. Suivez l'assistant d'installation
3. Configurez SNMP si nécessaire
4. Ajoutez vos équipements à superviser

## Vérification

```bash
# Vérifier Apache
sudo systemctl status apache2

# Vérifier MariaDB
sudo systemctl status mysql

# Tester accès web
curl -I http://localhost
```

## Dépannage

```bash
# Logs Apache
sudo tail -f /var/log/apache2/error.log

# Vérifier PHP
php -m

# Vérifier SNMP
snmpwalk -v2c -c public localhost
```

## Documentation
- Site officiel : https://www.cacti.net/
- Documentation : https://docs.cacti.net/
- GitHub : https://github.com/Cacti/cacti

## Notes
- Assurez-vous que SNMP est correctement configuré pour collecter les données
- Pensez à sécuriser l'accès web (authentification, HTTPS)
- Configurez des tâches cron pour la collecte des données