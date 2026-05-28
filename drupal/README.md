# Installation de Drupal

## Description
Drupal est un CMS open source puissant permettant de créer des sites web complexes, des portails et des applications web évolutives.

## Prérequis
- Système d'exploitation : Ubuntu/Debian Linux (ou autre distribution compatible)
- Accès : root ou sudo
- Connexion Internet
- Serveur web (Apache recommandé)
- Base de données (MySQL/MariaDB ou PostgreSQL)
- PHP installé (version compatible Drupal)

## Installation

### Méthode automatique (recommandée)

```bash
bash install_drupal.sh
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

#### 3. Installation de Composer (recommandé)
```bash
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
```

#### 4. Téléchargement de Drupal
```bash
cd /var/www/html
wget https://www.drupal.org/download-latest/tar.gz
tar -xvzf tar.gz
mv drupal-* drupal
```

#### 5. Permissions
```bash
sudo chown -R www-data:www-data /var/www/html/drupal
sudo chmod -R 755 /var/www/html/drupal
```

#### 6. Configuration Apache
```bash
sudo nano /etc/apache2/sites-available/drupal.conf
```

Contenu :
```
<VirtualHost *:80>
    ServerName votre-domaine.com
    DocumentRoot /var/www/html/drupal

    <Directory /var/www/html/drupal>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

Activation :
```bash
sudo a2ensite drupal.conf
sudo systemctl reload apache2
```

## Configuration

### Installation via navigateur
Accédez à :
```
http://votre-serveur/drupal
```

Puis suivez l'assistant :
- Choix de la langue
- Configuration base de données
- Création compte administrateur

### Fichiers importants
- `/var/www/html/drupal/sites/` — configuration sites
- `/var/www/html/drupal/modules/` — modules
- `/var/www/html/drupal/themes/` — thèmes

## Vérification

```bash
# Apache
sudo systemctl status apache2

# PHP
php -v

# Test accès
curl -I http://localhost/drupal
```

## Dépannage

```bash
# Logs Apache
sudo tail -f /var/log/apache2/error.log

# Vérifier PHP modules
php -m

# Redémarrer services
sudo systemctl restart apache2
```

## Documentation
- Site officiel : https://www.drupal.org/
- Documentation : https://www.drupal.org/documentation

## Notes
- Drupal est très flexible mais plus complexe que WordPress
- Idéal pour sites avancés et plateformes personnalisées
- Recommandé de sécuriser avec HTTPS (Let's Encrypt)