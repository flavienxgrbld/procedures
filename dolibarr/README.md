# Installation de Dolibarr

## Description
Dolibarr est un ERP/CRM open source destiné aux PME, permettant de gérer la facturation, les clients, les stocks, les projets et la comptabilité.

## Prérequis
- Système d'exploitation : Ubuntu/Debian Linux (ou autre distribution compatible)
- Accès : root ou sudo
- Connexion Internet
- Serveur web (Apache recommandé)
- Base de données (MySQL/MariaDB)
- PHP installé

## Installation

### Méthode automatique (recommandée)

```bash
bash install_dolibarr.sh
```

### Installation manuelle (étapes détaillées)

#### 1. Mise à jour du système
```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. Installation des dépendances
```bash
sudo apt install apache2 mariadb-server php php-mysql php-gd php-xml php-mbstring php-curl php-zip unzip wget -y
```

#### 3. Sécurisation de la base de données
```bash
sudo mysql_secure_installation
```

#### 4. Création de la base de données
```bash
sudo mysql -u root -p
```

Dans MySQL :
```sql
CREATE DATABASE dolibarr;
CREATE USER 'dolibarr'@'localhost' IDENTIFIED BY 'motdepasse';
GRANT ALL PRIVILEGES ON dolibarr.* TO 'dolibarr'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

#### 5. Téléchargement de Dolibarr
```bash
cd /var/www/html
wget https://github.com/Dolibarr/dolibarr/archive/refs/tags/latest.tar.gz
tar -xvzf latest.tar.gz
mv dolibarr-* dolibarr
```

#### 6. Permissions
```bash
sudo chown -R www-data:www-data /var/www/html/dolibarr
sudo chmod -R 755 /var/www/html/dolibarr
```

#### 7. Configuration Apache
```bash
sudo nano /etc/apache2/sites-available/dolibarr.conf
```

Contenu :
```
<VirtualHost *:80>
    ServerName votre-domaine.com
    DocumentRoot /var/www/html/dolibarr/htdocs

    <Directory /var/www/html/dolibarr/htdocs>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

Activation :
```bash
sudo a2ensite dolibarr.conf
sudo systemctl reload apache2
```

## Configuration

### Installation via navigateur
Accédez à :
```
http://votre-serveur/dolibarr
```

Puis suivez l’assistant :
- Configuration base de données
- Création utilisateur admin
- Paramètres société

### Répertoires importants
- `/var/www/html/dolibarr/htdocs/` — application web
- `/var/www/html/dolibarr/documents/` — fichiers

## Vérification

```bash
# Apache
sudo systemctl status apache2

# MariaDB
sudo systemctl status mysql

# Test accès web
curl -I http://localhost/dolibarr
```

## Dépannage

```bash
# Logs Apache
sudo tail -f /var/log/apache2/error.log

# Vérifier PHP
php -v

# Redémarrer services
sudo systemctl restart apache2
sudo systemctl restart mysql
```

## Documentation
- Site officiel : https://www.dolibarr.org/
- Documentation : https://wiki.dolibarr.org/

## Notes
- Dolibarr est très modulaire (CRM, ERP, facturation, stock)
- Peut être utilisé en mode SaaS ou local
- Pensez à sécuriser l’accès (HTTPS recommandé)