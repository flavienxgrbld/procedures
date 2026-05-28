# Installation de DokuWiki

## Description
DokuWiki est un wiki léger, open source et facile à utiliser, ne nécessitant pas de base de données. Il est souvent utilisé pour la documentation interne et les petites équipes.

## Prérequis
- Système d'exploitation : Ubuntu/Debian Linux (ou autre distribution compatible)
- Accès : root ou sudo
- Connexion Internet
- Serveur web (Apache ou Nginx recommandé)
- PHP installé (version récente recommandée)

## Installation

### Méthode automatique (recommandée)

```bash
bash install_dokuwiki.sh
```

### Installation manuelle (étapes détaillées)

#### 1. Mise à jour du système
```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. Installation du serveur web et PHP
```bash
sudo apt install apache2 php libapache2-mod-php php-xml php-mbstring php-curl unzip wget -y
```

#### 3. Téléchargement de DokuWiki
```bash
cd /var/www/html
wget https://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz
tar -xvzf dokuwiki-stable.tgz
mv dokuwiki-* dokuwiki
```

#### 4. Permissions
```bash
sudo chown -R www-data:www-data /var/www/html/dokuwiki
sudo chmod -R 755 /var/www/html/dokuwiki
```

#### 5. Configuration Apache (optionnel mais recommandé)
```bash
sudo nano /etc/apache2/sites-available/dokuwiki.conf
```

Contenu :
```
<VirtualHost *:80>
    ServerName votre-domaine.com
    DocumentRoot /var/www/html/dokuwiki

    <Directory /var/www/html/dokuwiki>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

Activation :
```bash
sudo a2ensite dokuwiki.conf
sudo systemctl reload apache2
```

## Configuration

### Accès initial
Une fois installé, accédez à :
```
http://votre-serveur/dokuwiki/install.php
```

Suivez l'assistant pour :
- Créer l'administrateur
- Configurer le wiki
- Définir les permissions

### Fichiers importants
- `/var/www/html/dokuwiki/conf/` — configuration
- `/var/www/html/dokuwiki/data/` — contenu du wiki

## Vérification

```bash
# Vérifier Apache
sudo systemctl status apache2

# Vérifier PHP
php -v

# Tester accès web
curl -I http://localhost/dokuwiki
```

## Dépannage

```bash
# Logs Apache
sudo tail -f /var/log/apache2/error.log

# Vérifier permissions
ls -l /var/www/html/dokuwiki

# Redémarrer Apache
sudo systemctl restart apache2
```

## Documentation
- Site officiel : https://www.dokuwiki.org/
- Documentation : https://www.dokuwiki.org/manual

## Notes
- DokuWiki ne nécessite pas de base de données
- Idéal pour la documentation interne et les projets techniques
- Pensez à désactiver `install.php` après installation pour des raisons de sécurité