# Installation d'Apache

## Description
Apache HTTP Server est un serveur web modulaire open-source largement utilisé pour servir des pages web. Il est connu pour sa fiabilité, sa flexibilité et ses nombreuses fonctionnalités.

## Prérequis
- Système d'exploitation : Ubuntu/Debian, CentOS/RHEL, SUSE, Arch Linux ou autres distributions Linux supportées
- Accès : Root ou sudo
- Connexion Internet pour télécharger les paquets

## Installation

### Méthode automatique (recommandée)
Exécutez le script d'installation fourni :

```bash
bash install_apache.sh
```

### Étapes détaillées manuelles

1. **Installation d'Apache**
   - Sur Ubuntu/Debian :
     ```bash
     sudo apt update
     sudo apt install apache2 apache2-utils -y
     ```
   - Sur CentOS/RHEL :
     ```bash
     sudo yum install httpd httpd-utils -y  # ou dnf pour CentOS 8+
     ```
   - Sur SUSE :
     ```bash
     sudo zypper install apache2 apache2-utils -y
     ```
   - Sur Arch Linux :
     ```bash
     sudo pacman -S apache -y
     ```

2. **Activation et démarrage du service**
   ```bash
   sudo systemctl enable apache2  # ou httpd selon la distribution
   sudo systemctl start apache2
   ```

3. **Configuration du firewall (si UFW est installé)**
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

Contenu exemple :
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

- Vérifiez que le service est actif :
  ```bash
  sudo systemctl status apache2  # ou httpd
  ```
- Testez l'accès : Ouvrez un navigateur et allez à `http://localhost`
- Vérifiez les logs d'erreur : `sudo tail -f /var/log/apache2/error.log`

## Modules utiles
- Activez des modules si nécessaire :
  ```bash
  sudo a2enmod rewrite  # Pour les réécritures d'URL
  sudo a2enmod ssl      # Pour HTTPS
  sudo systemctl reload apache2
  ```

## Dépannage

- Si le port 80 est occupé : `sudo netstat -tlnp | grep :80`
- Erreurs de permission : Vérifiez les permissions des fichiers web
- Problèmes de modules : `sudo apache2ctl -M` pour lister les modules chargés

## Documentation
- [Site officiel d'Apache](https://httpd.apache.org/)
- [Documentation Ubuntu/Debian](https://ubuntu.com/server/docs/web-servers-apache)
- [Documentation CentOS](https://docs.centos.org/en-US/centos/install-guide/Web_Servers/)

## Notes
- Apache est hautement configurable via les fichiers .htaccess dans les répertoires web.
- Pensez à sécuriser votre serveur avec HTTPS en utilisant Let's Encrypt.
- Pour les performances, considérez l'utilisation de modules comme mod_pagespeed.
