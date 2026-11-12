# Dolibarr — procédure d'installation

## Description

Dolibarr est un logiciel de gestion (ERP/CRM) libre pour les TPE, PME, associations et indépendants : tiers, devis, factures, stocks, comptabilité, agenda. Cette procédure l'installe sur une pile Apache, PHP et MariaDB.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu |
| **Méthode** | Archive des sources officielles |
| **Dossier** | `/var/www/dolibarr` (racine web : `htdocs/`) |
| **Ports** | 80/tcp |
| **Script** | `install_dolibarr.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- 1 Go de RAM au minimum.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/dolibarr
sudo bash install_dolibarr.sh
```

Le script installe Apache, MariaDB et PHP, crée la base `dolibarr` avec un mot de passe aléatoire, télécharge la dernière version publiée sur GitHub (ou `DOLIBARR_VERSION`), prépare `/var/lib/dolibarr/documents` et publie le dossier `htdocs/` avec Apache. Il reste à suivre l'assistant (étape 5) avec les informations de `/root/dolibarr_identifiants.txt`, puis à verrouiller l'installation (étape 6). Variables facultatives : `DOLIBARR_DOMAIN`, `DOLIBARR_DB_PASS`.

## Installation manuelle

### 1. Installer Apache, MariaDB et PHP

```bash
sudo apt update
sudo apt install -y apache2 mariadb-server unzip
sudo apt install -y php libapache2-mod-php php-mysql php-gd php-xml php-zip php-intl php-curl php-mbstring php-imap php-soap
```

### 2. Créer la base de données

```bash
sudo mysql_secure_installation
sudo mysql -u root -p
```

```sql
CREATE DATABASE dolibarr CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'dolibarr'@'localhost' IDENTIFIED BY 'MotDePasseFort';
GRANT ALL PRIVILEGES ON dolibarr.* TO 'dolibarr'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3. Télécharger Dolibarr

Récupérer la dernière version sur la page des versions (24.0.3 au 12/11/2026) :

```bash
cd /tmp
wget https://github.com/Dolibarr/dolibarr/archive/refs/tags/24.0.3.tar.gz -O dolibarr.tar.gz
sudo mkdir -p /var/www/dolibarr
sudo tar -xzf dolibarr.tar.gz -C /var/www/dolibarr --strip-components=1
sudo mkdir -p /var/lib/dolibarr/documents
sudo touch /var/www/dolibarr/htdocs/conf/conf.php
sudo chown -R www-data:www-data /var/www/dolibarr /var/lib/dolibarr
```

### 4. Créer le site Apache

```bash
sudo nano /etc/apache2/sites-available/dolibarr.conf
```

```apache
<VirtualHost *:80>
    ServerName erp.exemple.local
    DocumentRoot /var/www/dolibarr/htdocs

    <Directory /var/www/dolibarr/htdocs>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

```bash
sudo a2ensite dolibarr
sudo a2dissite 000-default
sudo systemctl reload apache2
```

### 5. Lancer l'assistant d'installation

Ouvrir `http://<adresse-du-serveur>/install/` et suivre les étapes :

1. Vérification des prérequis PHP.
2. Répertoire des documents : `/var/lib/dolibarr/documents`.
3. Base de données : serveur `localhost`, base `dolibarr`, utilisateur `dolibarr` et son mot de passe.
4. Création du compte administrateur.

### 6. Verrouiller l'installation

```bash
sudo touch /var/lib/dolibarr/documents/install.lock
sudo chmod 444 /var/www/dolibarr/htdocs/conf/conf.php
```

## Vérification

Se connecter sur `http://<adresse-du-serveur>/` avec le compte administrateur, puis activer les modules utiles dans *Accueil → Configuration → Modules/Applications*.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/var/www/dolibarr/htdocs/` | Application (racine web) |
| `/var/www/dolibarr/htdocs/conf/conf.php` | Configuration (base de données) |
| `/var/lib/dolibarr/documents/` | Documents générés et téléversés |

## Dépannage

- **L'assistant ne peut pas écrire `conf.php`** : le fichier doit exister et appartenir à `www-data` avant l'installation (étape 3).
- Journaux : `/var/log/apache2/error.log`.

## Points d'attention

- Sans le verrouillage de l'étape 6 (`install.lock`), l'assistant d'installation reste accessible.
- Sur Debian 13 (PHP 8.4), le module `php-imap` n'existe plus : Dolibarr fonctionne, seule la collecte automatique d'e-mails IMAP est indisponible.
- Le script désactive le site Apache par défaut (`000-default`) : Dolibarr répond sur l'adresse IP du serveur.
- Relu et mis à jour le 12/11/2026 (Dolibarr 24.0.3).

## Sources

- [Téléchargements Dolibarr](https://www.dolibarr.org/downloads.php)
- [Wiki Dolibarr — installation](https://wiki.dolibarr.org/index.php/Installation_-_Upgrade)
