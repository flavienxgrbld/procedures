# MediaWiki — procédure d'installation

## Description

MediaWiki est le moteur de wiki qui fait fonctionner Wikipédia. Il convient aux bases de connaissances importantes : historique des versions, catégories, modèles, gestion fine des droits et nombreuses extensions. Cette procédure installe la version LTS 1.43 sur une pile Apache, PHP et MariaDB.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu |
| **Méthode** | Archive officielle (version LTS 1.43) |
| **Dossier** | `/var/www/mediawiki` |
| **Ports** | 80/tcp |
| **Script** | `install_mediawiki.sh` |

## Prérequis

- PHP 8.1 ou plus récent, Apache, MariaDB.
- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/mediawiki
sudo bash install_mediawiki.sh
```

Le script installe Apache, MariaDB et PHP, crée la base `wiki`, télécharge MediaWiki 1.43 (LTS) et lance **l'installateur en ligne de commande** (`maintenance/run.php install`) : `LocalSettings.php` est généré directement sur le serveur, sans passer par l'assistant web (étapes 5 et 6). Le compte administrateur et les mots de passe sont enregistrés dans `/root/mediawiki_identifiants.txt`. Variables facultatives : `MW_VERSION`, `MW_NAME`, `MW_ADMIN`, `MW_ADMIN_PASS`, `MW_SERVER`, `MW_LANG`.

## Installation manuelle

### 1. Installer Apache, MariaDB et PHP

```bash
sudo apt update
sudo apt install -y apache2 mariadb-server
sudo apt install -y php libapache2-mod-php php-mysql php-xml php-mbstring php-intl php-gd php-curl php-apcu
```

### 2. Créer la base de données

```bash
sudo mysql -u root
```

```sql
CREATE DATABASE wiki CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'wiki'@'localhost' IDENTIFIED BY 'MotDePasseFort';
GRANT ALL PRIVILEGES ON wiki.* TO 'wiki'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3. Télécharger MediaWiki

```bash
cd /tmp
wget https://releases.wikimedia.org/mediawiki/1.43/mediawiki-1.43.11.tar.gz   # 1.43.11 au 12/11/2026
sudo mkdir -p /var/www/mediawiki
sudo tar -xzf mediawiki-1.43.11.tar.gz -C /var/www/mediawiki --strip-components=1
sudo chown -R www-data:www-data /var/www/mediawiki
```

### 4. Créer le site Apache

```bash
sudo nano /etc/apache2/sites-available/mediawiki.conf
```

```apache
<VirtualHost *:80>
    ServerName wiki.exemple.local
    DocumentRoot /var/www/mediawiki

    <Directory /var/www/mediawiki>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

```bash
sudo a2ensite mediawiki
sudo a2dissite 000-default
sudo systemctl reload apache2
```

### 5. Assistant d'installation

Ouvrir `http://<adresse-du-serveur>/` puis *Configurer le wiki* :

1. langue du wiki : français ;
2. base de données : `localhost`, base `wiki`, utilisateur `wiki` ;
3. nom du wiki et compte administrateur ;
4. options (droits, envoi de fichiers, extensions).

L'assistant génère `LocalSettings.php` à télécharger.

### 6. Installer `LocalSettings.php`

Copier le fichier téléchargé sur le serveur :

```bash
sudo mv LocalSettings.php /var/www/mediawiki/
sudo chown www-data:www-data /var/www/mediawiki/LocalSettings.php
sudo chmod 640 /var/www/mediawiki/LocalSettings.php
```

Recharger la page : le wiki s'affiche.

## Vérification

Se connecter avec le compte administrateur et modifier la page d'accueil. *Page spéciale:Version* (`Special:Version`) affiche les versions de MediaWiki, PHP et MariaDB.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/var/www/mediawiki/LocalSettings.php` | Configuration (base, droits, extensions) |
| `/var/www/mediawiki/images/` | Fichiers envoyés |
| `/var/www/mediawiki/extensions/` | Extensions |

## Dépannage

- Pour un wiki interne, interdire la création de comptes et la lecture anonyme dans `LocalSettings.php` :

```php
$wgGroupPermissions['*']['createaccount'] = false;
$wgGroupPermissions['*']['read'] = false;
$wgGroupPermissions['*']['edit'] = false;
```

## Points d'attention

- La branche LTS 1.43 est maintenue jusqu'à fin 2027 ; les versions intermédiaires (1.44 à 1.46) ont une durée de vie d'un an seulement.
- Par défaut, tout visiteur peut créer un compte et modifier les pages : pour un wiki interne, régler `$wgGroupPermissions` dans `LocalSettings.php`.
- L'exécution de PHP est désactivée dans le dossier `images/` (fichiers envoyés) par le site Apache du script.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Installer MediaWiki](https://www.mediawiki.org/wiki/Manual:Installing_MediaWiki)
- [Téléchargement](https://www.mediawiki.org/wiki/Download)
