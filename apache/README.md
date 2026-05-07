# Installation d'Apache

## Description
Apache HTTP Server est un serveur web modulaire open source largement utilisé pour servir des pages web. Il est connu pour sa fiabilité, sa flexibilité et ses nombreuses fonctionnalités.

## Prérequis
- Système d'exploitation : Ubuntu/Debian, CentOS/RHEL, SUSE, Arch Linux ou autres distributions Linux compatibles
- Accès : root ou sudo
- Connexion Internet pour télécharger les paquets

## Installation

### Méthode automatique (recommandée)
Exécutez le script d'installation fourni :

```bash
bash install_apache.sh
```

### Installation manuelle (étapes détaillées)

#### 1. Installation d'Apache

- **Ubuntu/Debian**
```bash
sudo apt update
sudo apt install apache2 apache2-utils -y
```

- **CentOS/RHEL**
```bash
sudo yum install httpd httpd-utils -y  # ou dnf pour CentOS 8+
```

- **SUSE**
```bash
sudo zypper install apache2 apache2-utils -y
```

- **Arch Linux**
```bash
sudo pacman -S apache
```

#### 2. Activation et démarrage du service
```bash
sudo systemctl enable apache2  # ou httpd selon la distribution
sudo systemctl start apache2
```

#### 3. Configuration du firewall (si UFW est installé)
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## Configuration

### Fichiers de configuration principaux
- Ubuntu/Debian : `/etc/apache2/apache2.conf`
- CentOS/RHEL : `/etc/httpd/conf/httpd.conf`
- SUSE : `/etc/apache2/httpd.conf`

### Répertoires importants
- Sites disponibles : `/etc/apache2/sites-available/` (Ubuntu/Debian)
- Sites activés : `/etc/apache2/sites-enabled/` (Ubuntu/Debian)
- Répertoire web par défaut : `/var/www/html`

### Exemple de configuration d'un site virtuel (Ubuntu/Debian)

Créez un fichier de configuration :
```bash
sudo nano /etc/apache2/sites-available/mon-site.conf
```

Contenu :
```
<VirtualHost *:80>
    ServerName mon-domaine.com
    DocumentRoot /var/www/mon-site

    <Directory /var/www/mon-site>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

Activez le site :
```bash
sudo a2ensite mon-site.conf
sudo systemctl reload apache2
```

## Vérification

```bash
# Vérifier que le service est actif
sudo systemctl status apache2  # ou httpd

# Tester l'accès (depuis le serveur)
curl -I http://localhost

# Voir les logs d'erreur
sudo tail -f /var/log/apache2/error.log
```

## Modules utiles

```bash
# Réécriture d'URL
sudo a2enmod rewrite

# HTTPS
sudo a2enmod ssl

# Rechargement
sudo systemctl reload apache2
```

## Dépannage

```bash
# Port 80 déjà utilisé
sudo netstat -tlnp | grep :80

# Modules chargés
sudo apache2ctl -M

# Vérification configuration
sudo apache2ctl configtest
```

## Documentation
- Site officiel : https://httpd.apache.org/
- Documentation Ubuntu : https://ubuntu.com/server/docs/web-servers-apache
- Documentation CentOS : https://docs.centos.org/en-US/centos/install-guide/Web_Servers/

## Notes
- Apache est hautement configurable via les fichiers `.htaccess`
- Pensez à sécuriser votre serveur avec HTTPS (Let's Encrypt recommandé)
- Pour de meilleures performances, vous pouvez utiliser des modules comme `mod_pagespeed`