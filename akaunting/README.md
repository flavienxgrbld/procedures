# Akaunting — procédure d'installation

## Description

Akaunting est un logiciel de comptabilité en ligne, libre et auto-hébergé, destiné aux petites entreprises et aux indépendants (factures, dépenses, clients, rapports). Cette procédure l'installe sur une pile Apache, PHP 8.1 et MariaDB.

| | |
|---|---|
| **Systèmes** | Debian 11+ / Ubuntu 20.04+ (dnf, zypper et pacman gérés par la bibliothèque commune) |
| **Méthode** | Code source depuis GitHub + Composer |
| **Dossier** | `/var/www/akaunting` |
| **Ports** | 80/tcp (HTTP) |
| **Script** | `install_akaunting.sh` |

## Prérequis

- Une machine Debian ou Ubuntu à jour, avec un accès root (`sudo`).
- Une connexion Internet : le script télécharge sa bibliothèque commune, PHP, Composer et le code d'Akaunting.
- 2 Go de RAM conseillés (Composer est gourmand pendant l'installation).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/akaunting
sudo bash install_akaunting.sh
```

Le script installe PHP 8.1, Apache, MariaDB, Composer, puis récupère Akaunting dans `/var/www/akaunting`. Lire les **points d'attention** avant de l'utiliser : la base de données et le site Apache restent à configurer.

## Installation manuelle

### 1. Mettre le système à jour

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Installer Apache, MariaDB et PHP 8.1

Si PHP 8.1 n'est pas dans les dépôts de la distribution, ajouter le dépôt Sury (Debian) ou `ppa:ondrej/php` (Ubuntu), comme le fait le script.

```bash
sudo apt install -y apache2 mariadb-server git unzip
sudo apt install -y php8.1 php8.1-cli php8.1-common php8.1-mysql php8.1-zip php8.1-gd \
  php8.1-mbstring php8.1-curl php8.1-xml php8.1-bcmath php8.1-intl libapache2-mod-php8.1
```

### 3. Créer la base de données

```bash
sudo mysql_secure_installation
sudo mysql -u root -p
```

```sql
CREATE DATABASE akaunting CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'akaunting'@'localhost' IDENTIFIED BY 'MotDePasseFort';
GRANT ALL PRIVILEGES ON akaunting.* TO 'akaunting'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 4. Installer Composer

```bash
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
```

### 5. Récupérer Akaunting et ses dépendances

```bash
cd /var/www
sudo git clone https://github.com/akaunting/akaunting.git
cd akaunting
sudo composer install --no-dev
sudo php artisan storage:link
sudo chown -R www-data:www-data /var/www/akaunting
```

### 6. Créer le site Apache

```bash
sudo nano /etc/apache2/sites-available/akaunting.conf
```

```apache
<VirtualHost *:80>
    ServerName compta.exemple.local
    DocumentRoot /var/www/akaunting

    <Directory /var/www/akaunting>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

```bash
sudo a2ensite akaunting
sudo a2dissite 000-default
sudo a2enmod rewrite
sudo systemctl reload apache2
```

### 7. Terminer l'installation dans le navigateur

Ouvrir `http://<adresse-du-serveur>/` : l'assistant d'Akaunting demande la langue, les informations de la base créée à l'étape 3, puis le compte administrateur.

## Vérification

```bash
systemctl status apache2 mariadb
php -v
curl -I http://localhost/
```

La page d'accueil doit répondre (code 200 ou 302 vers l'assistant d'installation).

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/var/www/akaunting` | Application |
| `/var/www/akaunting/.env` | Configuration (base de données, URL), créé par l'assistant |
| `/etc/apache2/sites-available/akaunting.conf` | Site Apache |
| `/var/www/akaunting/storage/logs/` | Journaux de l'application |

## Dépannage

- **Erreur 500** : consulter `storage/logs/laravel.log` et `/var/log/apache2/error.log`, puis vérifier que `www-data` est bien propriétaire du dossier.
- **Page 404 sur les sous-pages** : le module `rewrite` n'est pas activé ou `AllowOverride All` manque.
- **Journal du script** : `/var/log/install_script.log`.

## Points d'attention

- Le script lance `php artisan migrate --force` sans avoir créé de base de données ni de fichier `.env` : cette étape échoue. Il faut créer la base (étape 3) et passer par l'assistant web (étape 7).
- Le script ne crée pas de site Apache : l'URL `http://votre-serveur/akaunting` qu'il affiche ne fonctionne pas tant que l'étape 6 n'est pas faite.
- Installé depuis GitHub, le code peut aussi nécessiter la compilation des fichiers front (`npm install && npm run prod`). L'archive officielle disponible sur akaunting.com contient déjà tout et évite Composer et npm.

## Sources

- [Documentation Akaunting — installation](https://akaunting.com/hc/docs/on-premise/requirements/)
- [Dépôt GitHub d'Akaunting](https://github.com/akaunting/akaunting)
