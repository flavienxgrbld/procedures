# Installation de GLPI 11.0.4 sur Debian/Ubuntu

## 1. Préparation du système

Passer en mode super-administrateur et mettre à jour les dépôts :

```bash
sudo su
apt update && apt upgrade -y
```

## 2. Installation des prérequis

Installation des outils nécessaires :

```bash
apt install -y lsb-release ca-certificates apt-transport-https \
software-properties-common gnupg2
```

## 3. Installation de PHP 8.2+

GLPI 11.x nécessite **PHP 8.2 minimum**. Ajouter le dépôt Sury :

```bash
curl -sSL https://packages.sury.org/php/README.txt | bash -x
apt update
```

## 4. Installation d'Apache2, PHP 8.2 et extensions

```bash
apt install -y apache2 \
    php8.2 \
    php8.2-apcu \
    php8.2-cli \
    php8.2-common \
    php8.2-curl \
    php8.2-gd \
    php8.2-imap \
    php8.2-ldap \
    php8.2-mysql \
    php8.2-xmlrpc \
    php8.2-xml \
    php8.2-mbstring \
    php8.2-bcmath \
    php8.2-intl \
    php8.2-zip \
    php8.2-redis \
    php8.2-bz2 \
    libapache2-mod-php8.2 \
    php8.2-soap \
    php-cas
```

Vérifier la version de PHP installée :

```bash
php -v
```

## 5. Installation de MariaDB

```bash
apt install -y mariadb-server
```

### Configuration de MariaDB

Lancer l'assistant de sécurisation :

```bash
mysql_secure_installation
```

Définir un mot de passe root fort et accepter toutes les options.

### Création de la base de données GLPI

Connexion à MariaDB :

```bash
mysql -u root -p
```

Dans MariaDB :

```sql
CREATE DATABASE glpi CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'glpi'@'localhost' IDENTIFIED BY 'EntreTonMotDePasseGLPI';
GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'localhost';
GRANT SELECT ON `mysql`.`time_zone_name` TO 'glpi'@'localhost';
FLUSH PRIVILEGES;
quit;
```

### Charger les fuseaux horaires MySQL

```bash
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql
```

## 6. Téléchargement et installation de GLPI

Téléchargement de GLPI 11.0.4 :

```bash
cd /tmp
wget https://github.com/glpi-project/glpi/releases/download/11.0.4/glpi-11.0.4.tgz
tar -xzf glpi-11.0.4.tgz -C /var/www/html/
rm -f glpi-11.0.4.tgz
```

### Création des répertoires de configuration

```bash
mkdir -p /etc/glpi
mkdir -p /var/lib/glpi
mkdir -p /var/log/glpi
```

## 7. Configuration de GLPI

### Création du fichier downstream.php

```bash
nano /var/www/html/glpi/inc/downstream.php
```

Contenu du fichier :

```php
<?php
define('GLPI_CONFIG_DIR', '/etc/glpi/');
if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
    require_once GLPI_CONFIG_DIR . '/local_define.php';
}
```

### Déplacement des répertoires

```bash
mv /var/www/html/glpi/config/* /etc/glpi/
rmdir /var/www/html/glpi/config
mv /var/www/html/glpi/files/* /var/lib/glpi/
rmdir /var/www/html/glpi/files
mv /var/lib/glpi/_log/* /var/log/glpi/
rmdir /var/lib/glpi/_log
```

### Création du fichier local_define.php

```bash
nano /etc/glpi/local_define.php
```

Contenu du fichier :

```php
<?php
define('GLPI_VAR_DIR', '/var/lib/glpi');
define('GLPI_DOC_DIR', GLPI_VAR_DIR);
define('GLPI_CACHE_DIR', GLPI_VAR_DIR . '/_cache');
define('GLPI_CRON_DIR', GLPI_VAR_DIR . '/_cron');
define('GLPI_GRAPH_DIR', GLPI_VAR_DIR . '/_graphs');
define('GLPI_LOCAL_I18N_DIR', GLPI_VAR_DIR . '/_locales');
define('GLPI_LOCK_DIR', GLPI_VAR_DIR . '/_lock');
define('GLPI_PICTURE_DIR', GLPI_VAR_DIR . '/_pictures');
define('GLPI_PLUGIN_DOC_DIR', GLPI_VAR_DIR . '/_plugins');
define('GLPI_RSS_DIR', GLPI_VAR_DIR . '/_rss');
define('GLPI_SESSION_DIR', GLPI_VAR_DIR . '/_sessions');
define('GLPI_TMP_DIR', GLPI_VAR_DIR . '/_tmp');
define('GLPI_UPLOAD_DIR', GLPI_VAR_DIR . '/_uploads');
define('GLPI_INVENTORY_DIR', GLPI_VAR_DIR . '/_inventories');
define('GLPI_THEMES_DIR', GLPI_VAR_DIR . '/_themes');
define('GLPI_LOG_DIR', '/var/log/glpi');
```

## 8. Configuration des permissions

```bash
chown -R root:root /var/www/html/glpi/
chown -R www-data:www-data /etc/glpi
chown -R www-data:www-data /var/lib/glpi
chown -R www-data:www-data /var/log/glpi
chown -R www-data:www-data /var/www/html/glpi/marketplace

find /var/www/html/glpi/ -type f -exec chmod 0644 {} \;
find /var/www/html/glpi/ -type d -exec chmod 0755 {} \;
find /etc/glpi -type f -exec chmod 0644 {} \;
find /etc/glpi -type d -exec chmod 0755 {} \;
find /var/lib/glpi -type f -exec chmod 0644 {} \;
find /var/lib/glpi -type d -exec chmod 0755 {} \;
find /var/log/glpi -type f -exec chmod 0644 {} \;
find /var/log/glpi -type d -exec chmod 0755 {} \;
```

## 9. Configuration d'Apache

### Création du VirtualHost

```bash
nano /etc/apache2/sites-available/glpi.conf
```

Contenu du fichier :

```apache
<VirtualHost *:80>
    ServerName yourglpi.yourdomain.com
    DocumentRoot /var/www/html/glpi/public
    
    <Directory /var/www/html/glpi/public>
        Require all granted
        RewriteEngine On
        
        # Ensure authorization headers are passed to PHP
        RewriteCond %{HTTP:Authorization} ^(.+)$
        RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
        
        # Redirect all requests to GLPI router, unless the file exists
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
</VirtualHost>
```

### Activation du site

```bash
a2dissite 000-default.conf
a2ensite glpi.conf
a2enmod rewrite
```

## 10. Configuration de PHP

Éditer le fichier de configuration PHP :

```bash
nano /etc/php/8.2/apache2/php.ini
```

Modifier les paramètres suivants :

```ini
upload_max_filesize = 20M
post_max_size = 20M
memory_limit = 256M
max_execution_time = 300
max_input_vars = 5000
session.cookie_httponly = On
date.timezone = Europe/Paris
```

### Redémarrage d'Apache

```bash
systemctl restart apache2
systemctl enable apache2
```

## 11. Accès à l'interface Web

Ouvrir un navigateur et accéder à :

```
http://IP_DU_SERVEUR/glpi
```

Suivre l'assistant d'installation avec les informations de base de données :

- **Serveur** : localhost
- **Base de données** : glpi
- **Utilisateur** : glpi
- **Mot de passe** : (celui défini précédemment)

### Identifiants par défaut GLPI

- **Super-Admin** : glpi / glpi
- **Technicien** : tech / tech
- **Utilisateur normal** : normal / normal
- **Post-only** : post-only / postonly

---

## ⚠️ IMPORTANT - Sécurité

Après la première connexion :

1. **Changer tous les mots de passe par défaut**
2. **Supprimer le répertoire d'installation** :

```bash
rm -rf /var/www/html/glpi/install
```

---

## 📋 Résumé des prérequis

- Debian 11+ ou Ubuntu 20.04+
- **PHP 8.2 minimum** (GLPI 11.x)
- Apache 2.4+
- MariaDB 10.3+ ou MySQL 8.0+
- 2 Go de RAM minimum (4 Go recommandés)
- 1 Go d'espace disque minimum

## 🔗 Liens utiles

- [Documentation officielle GLPI](https://glpi-project.org/documentation/)
- [GitHub GLPI](https://github.com/glpi-project/glpi)
- [Forum GLPI](https://forum.glpi-project.org/)
