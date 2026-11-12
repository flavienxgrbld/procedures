# Akaunting — procédure d'installation

## Description

Akaunting est un logiciel de comptabilité en ligne, libre et auto-hébergé, destiné aux petites entreprises et aux indépendants (factures, dépenses, clients, rapports). Cette procédure installe la dernière version (3.3) sur une pile Apache, PHP 8.2 ou plus récent et MariaDB.

| | |
|---|---|
| **Systèmes** | Debian 12/13, Ubuntu 22.04/24.04 |
| **Méthode** | Archive officielle (akaunting.com), déjà compilée |
| **Dossier** | `/var/www/akaunting` |
| **Ports** | 80/tcp (HTTP) |
| **Script** | `install_akaunting.sh` |

## Prérequis

- Une machine Debian ou Ubuntu à jour, avec un accès root (`sudo`).
- Une connexion Internet : le script télécharge les paquets et l'archive d'Akaunting.
- 1 Go de RAM minimum.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/akaunting
sudo bash install_akaunting.sh
```

Le script installe Apache, MariaDB et PHP (version de la distribution si elle est en 8.2 ou plus, sinon PHP 8.2 depuis le dépôt Sury ou `ppa:ondrej/php`). Il crée la base `akaunting` avec un mot de passe aléatoire, décompresse l'archive officielle dans `/var/www/akaunting` et publie le site Apache. Il reste à suivre l'assistant web (étape 6) avec les informations enregistrées dans `/root/akaunting_identifiants.txt`.

Variables facultatives : `AKAUNTING_DOMAIN` (nom du site) et `AKAUNTING_DB_PASS` (mot de passe de la base), par exemple `sudo AKAUNTING_DOMAIN=compta.exemple.local bash install_akaunting.sh`.

## Installation manuelle

### 1. Mettre le système à jour

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Installer Apache, MariaDB et PHP 8.2 ou plus

Akaunting 3.3 demande PHP 8.2 au minimum. Debian 12 (8.2), Debian 13 (8.4) et Ubuntu 24.04 (8.3) le fournissent ; sur Ubuntu 22.04 (8.1), ajouter d'abord `ppa:ondrej/php`. Remplacer `8.2` par la version installée.

```bash
sudo apt install -y apache2 mariadb-server git unzip
sudo apt install -y php8.2 php8.2-cli php8.2-common php8.2-mysql php8.2-zip php8.2-gd \
  php8.2-mbstring php8.2-curl php8.2-xml php8.2-bcmath php8.2-intl libapache2-mod-php8.2
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

### 4. Télécharger Akaunting

L'archive officielle contient déjà les dépendances PHP et les fichiers compilés : ni Composer ni npm ne sont nécessaires.

```bash
cd /tmp
wget -O akaunting.zip "https://akaunting.com/download.php?version=latest"
sudo mkdir -p /var/www/akaunting
sudo unzip -o akaunting.zip -d /var/www/akaunting
sudo chown -R www-data:www-data /var/www/akaunting
```

### 5. Créer le site Apache

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

### 6. Terminer l'installation dans le navigateur

Ouvrir `http://<adresse-du-serveur>/` : l'assistant d'Akaunting demande la langue, les informations de la base créée à l'étape 3 (ou dans `/root/akaunting_identifiants.txt` avec le script), puis le compte administrateur.

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

- Le script désactive le site Apache par défaut (`000-default`) : Akaunting répond sur l'adresse IP du serveur. Sur une machine qui héberge déjà d'autres sites, définir `AKAUNTING_DOMAIN` et un enregistrement DNS correspondant.
- Le site est publié en HTTP. Pour un accès depuis Internet, ajouter HTTPS (procédure Certbot).
- Relu et mis à jour le 12/11/2026 : Akaunting 3.3.1, PHP 8.2 minimum.

## Sources

- [Documentation Akaunting — installation](https://akaunting.com/hc/docs/on-premise/requirements/)
- [Dépôt GitHub d'Akaunting](https://github.com/akaunting/akaunting)
- [composer.json d'Akaunting 3.3.1 (version de PHP requise)](https://github.com/akaunting/akaunting/blob/3.3.1/composer.json)
