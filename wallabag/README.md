# Wallabag — procédure d'installation

## Description

Wallabag est une application libre de lecture différée, alternative à Pocket : on y enregistre des articles web, qui sont extraits sans publicité pour être lus plus tard, sur le navigateur, une liseuse ou les applications mobiles, avec étiquettes et annotations. Cette procédure installe la version 2.6.14 sur une pile Apache, PHP et MariaDB.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu |
| **Méthode** | Archive de version officielle (GitHub) |
| **Dossier** | `/var/www/wallabag` (racine web : `web/`) |
| **Ports** | 80/tcp |
| **Script** | `install_wallabag.sh` |

## Prérequis

- PHP 8.1 ou plus récent, Apache, MariaDB.
- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/wallabag
sudo bash install_wallabag.sh
```

Le script installe Apache, MariaDB et PHP, crée la base (mot de passe aléatoire), télécharge l'archive de version 2.6.15 depuis GitHub, renseigne `parameters.yml` (étape 4), initialise la base sans question (`wallabag:install --no-interaction`), donne un mot de passe aléatoire au compte `wallabag` et publie le dossier `web/` avec Apache. Identifiants : `/root/wallabag_identifiants.txt`. Variables facultatives : `WALLABAG_VERSION`, `WALLABAG_URL`.

## Installation manuelle

### 1. Installer Apache, MariaDB et PHP

```bash
sudo apt update
sudo apt install -y apache2 mariadb-server
sudo apt install -y php libapache2-mod-php php-mysql php-xml php-curl php-gd php-intl php-mbstring php-bcmath php-tidy php-zip
```

### 2. Créer la base de données

```bash
sudo mysql -u root
```

```sql
CREATE DATABASE wallabag CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'wallabag'@'localhost' IDENTIFIED BY 'MotDePasseFort';
GRANT ALL PRIVILEGES ON wallabag.* TO 'wallabag'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3. Télécharger Wallabag

```bash
cd /tmp
wget https://github.com/wallabag/wallabag/releases/download/2.6.15/wallabag-2.6.15.tar.gz
sudo mkdir -p /var/www/wallabag
sudo tar -xzf wallabag-2.6.15.tar.gz -C /var/www/wallabag --strip-components=1
```

### 4. Renseigner la configuration

Dans `/var/www/wallabag/app/config/parameters.yml` :

```yaml
    database_driver: pdo_mysql
    database_host: 127.0.0.1
    database_port: 3306
    database_name: wallabag
    database_user: wallabag
    database_password: MotDePasseFort
    domain_name: http://wallabag.exemple.local
    secret: <chaîne aléatoire : openssl rand -hex 32>
```

### 5. Initialiser la base et créer l'administrateur

```bash
cd /var/www/wallabag
sudo chown -R www-data:www-data /var/www/wallabag
sudo -u www-data php bin/console wallabag:install --env=prod
```

La commande crée les tables et demande l'identifiant, l'e-mail et le mot de passe de l'administrateur.

### 6. Créer le site Apache

```bash
sudo nano /etc/apache2/sites-available/wallabag.conf
```

```apache
<VirtualHost *:80>
    ServerName wallabag.exemple.local
    DocumentRoot /var/www/wallabag/web

    <Directory /var/www/wallabag/web>
        AllowOverride None
        Require all granted
        <IfModule mod_rewrite.c>
            Options -MultiViews
            RewriteEngine On
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteRule ^(.*)$ app.php [QSA,L]
        </IfModule>
    </Directory>
</VirtualHost>
```

```bash
sudo a2enmod rewrite
sudo a2ensite wallabag
sudo a2dissite 000-default
sudo systemctl reload apache2
```

## Vérification

Ouvrir `http://wallabag.exemple.local`, se connecter, puis enregistrer un article avec **+** (coller l'adresse d'une page) : il s'affiche sans publicité.

## Points d'attention

- Le compte créé par l'installation s'appelle `wallabag` : le script remplace son mot de passe par défaut.
- La racine web doit être le dossier `web/`, et non le dossier de l'application (fichiers de configuration).
- Le script désactive le site Apache par défaut (`000-default`).
- Relu et mis à jour le 12/11/2026.

## Sources

- [Installer Wallabag](https://doc.wallabag.org/admin/installation/installation/)
- [Configuration du serveur web](https://doc.wallabag.org/admin/installation/virtualhosts/)
