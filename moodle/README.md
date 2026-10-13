# Moodle — procédure d'installation

## Description

Moodle est la plateforme d'apprentissage en ligne (LMS) libre la plus utilisée dans l'enseignement : cours, devoirs, quiz, forums, suivi des notes et des compétences. Cette procédure installe Moodle 5.3 sur une pile Apache, PHP 8.3 et MariaDB.

| | |
|---|---|
| **Systèmes** | Debian 13, Ubuntu 24.04 (ou distribution avec PHP 8.3) |
| **Méthode** | Archive officielle `download.moodle.org` |
| **Dossiers** | `/var/www/moodle` (code, racine web : `public/`) et `/var/moodledata` (données) |
| **Ports** | 80/tcp |
| **Script** | `install_moodle.sh` |

## Prérequis

- PHP 8.3 ou plus récent, Apache, MariaDB 10.11+ ou PostgreSQL.
- 2 Go de RAM au minimum.
- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/moodle
sudo bash install_moodle.sh
```

Lire les points d'attention : sur Debian et Ubuntu, le script échoue à l'installation des modules PHP.

## Installation manuelle

### 1. Installer Apache, MariaDB et PHP

```bash
sudo apt update
sudo apt install -y apache2 mariadb-server
sudo apt install -y php libapache2-mod-php php-mysql php-xml php-mbstring php-curl php-zip \
  php-gd php-intl php-soap php-sodium php-opcache
php -v
```

Si `php -v` indique une version inférieure à 8.3, ajouter le dépôt Sury (Debian) ou `ppa:ondrej/php` (Ubuntu).

### 2. Régler PHP

Dans `/etc/php/8.3/apache2/php.ini` et `/etc/php/8.3/cli/php.ini` :

```ini
max_input_vars = 5000
memory_limit = 256M
upload_max_filesize = 100M
post_max_size = 100M
```

### 3. Créer la base de données

```bash
sudo mysql -u root
```

```sql
CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'moodle'@'localhost' IDENTIFIED BY 'MotDePasseFort';
GRANT ALL PRIVILEGES ON moodle.* TO 'moodle'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 4. Télécharger Moodle et créer le dossier de données

```bash
cd /tmp
wget https://download.moodle.org/download.php/direct/stable503/moodle-latest-503.tgz
sudo tar -xzf moodle-latest-503.tgz -C /var/www/
sudo mkdir -p /var/moodledata
sudo chown -R www-data:www-data /var/moodledata
sudo chmod 0770 /var/moodledata
sudo chown -R root:www-data /var/www/moodle
```

Le dossier de données doit rester **hors** de la racine web.

### 5. Créer le site Apache

```bash
sudo nano /etc/apache2/sites-available/moodle.conf
```

```apache
<VirtualHost *:80>
    ServerName moodle.exemple.local
    DocumentRoot /var/www/moodle/public

    <Directory /var/www/moodle/public>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

```bash
sudo a2ensite moodle
sudo a2dissite 000-default
sudo systemctl restart apache2
```

### 6. Installer Moodle

Par l'assistant web (`http://moodle.exemple.local/`) ou en ligne de commande :

```bash
sudo -u www-data /usr/bin/php /var/www/moodle/admin/cli/install.php \
  --lang=fr --wwwroot=http://moodle.exemple.local --dataroot=/var/moodledata \
  --dbtype=mariadb --dbname=moodle --dbuser=moodle --dbpass=MotDePasseFort \
  --fullname="Moodle du labo" --shortname="Labo" \
  --adminuser=admin --adminpass='AdminMotDePasse1!' --adminemail=admin@exemple.local \
  --agree-license --non-interactive
```

L'installateur écrit `config.php`, qui doit appartenir à `root:www-data` en lecture seule.

### 7. Planifier la tâche cron

Moodle exige une tâche planifiée chaque minute :

```bash
echo '* * * * * www-data /usr/bin/php /var/www/moodle/admin/cli/cron.php > /dev/null' | sudo tee /etc/cron.d/moodle
```

## Vérification

Se connecter en administrateur : *Administration du site → Serveur → Environnement* et *Administration du site → Notifications* ne doivent signaler aucune erreur.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/var/www/moodle/config.php` | Configuration (base, URL, dossier de données) |
| `/var/moodledata/` | Fichiers déposés, cache, sessions |

## Points d'attention

- Le script installe les modules PHP sous les noms `php81-gd`, `php81-xml`, `php81-intl` et `php81-curl`. Sur Debian et Ubuntu, ce sont `php8.1-gd`, etc. : le script s'arrête.
- Il clone tout l'historique Git de Moodle (plusieurs Go) et choisit la branche `MOODLE_402_STABLE` : Moodle 4.2 n'est plus maintenu, et la version 5.3 demande PHP 8.3.
- Il ne crée ni base de données, ni site Apache, ni tâche cron : l'URL `/moodle` qu'il affiche ne fonctionne pas, car `/var/www/moodle` n'est pas servi par le site par défaut.
- Depuis Moodle 5.1, la racine web doit être le dossier `public/`, et non le dossier du code.

## Sources

- [Installation de Moodle](https://docs.moodle.org/fr/Installation_de_Moodle)
- [Téléchargements](https://download.moodle.org/releases/latest/)
