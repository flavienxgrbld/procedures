# Drupal — procédure d'installation

## Description

Drupal est un système de gestion de contenu (CMS) libre, robuste et très extensible, utilisé pour des sites institutionnels comme pour des portails complexes. Cette procédure installe la dernière version sur une pile Apache, PHP et MariaDB.

| | |
|---|---|
| **Systèmes** | Debian 12+, Ubuntu 22.04+ |
| **Méthode** | Archive officielle (`download-latest`) |
| **Dossier** | `/var/www/drupal` |
| **Ports** | 80/tcp |
| **Script** | `install_drupal.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- PHP 8.3 ou plus récent pour Drupal 11 (vérifier les prérequis de la version téléchargée).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/drupal
sudo bash install_drupal.sh
```

Le script installe Apache, PHP, MariaDB, télécharge Drupal et crée le site Apache. La base de données reste à créer (étape 2 ci-dessous) avant l'assistant web.

## Installation manuelle

### 1. Installer Apache, MariaDB et PHP

```bash
sudo apt update
sudo apt install -y apache2 mariadb-server
sudo apt install -y php libapache2-mod-php php-mysql php-gd php-xml php-mbstring php-curl php-zip php-intl php-opcache php-apcu
php -v
```

Si la version de PHP de la distribution est trop ancienne pour la version de Drupal, ajouter le dépôt Sury (Debian) ou `ppa:ondrej/php` (Ubuntu).

### 2. Créer la base de données

```bash
sudo mysql_secure_installation
sudo mysql -u root -p
```

```sql
CREATE DATABASE drupal CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER 'drupal'@'localhost' IDENTIFIED BY 'MotDePasseFort';
GRANT ALL PRIVILEGES ON drupal.* TO 'drupal'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3. Télécharger Drupal

```bash
cd /tmp
wget https://www.drupal.org/download-latest/tar.gz -O drupal.tar.gz
sudo mkdir -p /var/www/drupal
sudo tar -xzf drupal.tar.gz -C /var/www/drupal --strip-components=1
sudo chown -R www-data:www-data /var/www/drupal
```

### 4. Créer le site Apache

```bash
sudo nano /etc/apache2/sites-available/drupal.conf
```

```apache
<VirtualHost *:80>
    ServerName site.exemple.local
    DocumentRoot /var/www/drupal

    <Directory /var/www/drupal>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

```bash
sudo a2enmod rewrite
sudo a2ensite drupal
sudo a2dissite 000-default
sudo systemctl reload apache2
```

### 5. Lancer l'assistant d'installation

Ouvrir `http://<adresse-du-serveur>/` : choisir la langue, le profil **Standard**, saisir les informations de la base de l'étape 2, puis le nom du site et le compte administrateur.

### 6. Sécuriser le fichier de configuration

```bash
sudo chmod 444 /var/www/drupal/sites/default/settings.php
```

Dans `settings.php`, renseigner `$settings['trusted_host_patterns']` avec le nom du site pour supprimer l'avertissement du rapport d'état.

## Vérification

*Administration → Rapports → Rapport d'état* (`/admin/reports/status`) ne doit afficher aucune erreur.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/var/www/drupal/sites/default/settings.php` | Configuration (base, hôtes de confiance) |
| `/var/www/drupal/sites/default/files/` | Fichiers téléversés |
| `/var/www/drupal/modules/`, `themes/` | Modules et thèmes ajoutés |

## Dépannage

- **URL propres désactivées (404 sur les pages)** : `mod_rewrite` ou `AllowOverride All` manque.
- Erreurs PHP : `/var/log/apache2/error.log` et *Rapports → Messages récents*.

## Points d'attention

- Le script installe PHP 8.1, insuffisant pour les versions récentes de Drupal (Drupal 11 demande PHP 8.3). Vérifier la version requise avant l'installation.
- Le site Apache du script garde le site par défaut `000-default` actif : en accédant par l'adresse IP, c'est la page par défaut d'Apache qui s'affiche. Désactiver `000-default` comme à l'étape 4.
- Le script ne crée pas de base de données : il faut l'étape 2 avant l'assistant web.
- Pour un site maintenu dans la durée, l'installation recommandée par Drupal passe par Composer (`composer create-project drupal/recommended-project`).

## Sources

- [Installer Drupal](https://www.drupal.org/docs/getting-started/installing-drupal)
- [Prérequis système](https://www.drupal.org/docs/getting-started/system-requirements)
