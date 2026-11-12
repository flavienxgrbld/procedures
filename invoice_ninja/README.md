# Invoice Ninja — procédure d'installation

## Description

Invoice Ninja est une application libre de facturation : devis, factures, factures récurrentes, suivi des paiements et portail client. Cette procédure installe la version 5 sur une pile Apache, PHP et MariaDB.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu |
| **Méthode** | Archive officielle de version (GitHub) |
| **Dossier** | `/var/www/invoiceninja` (racine web : `public/`) |
| **Ports** | 80/tcp |
| **Script** | `install_invoice_ninja.sh` |

## Prérequis

- PHP 8.2 ou plus récent, Apache, MariaDB.
- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/invoice_ninja
sudo bash install_invoice_ninja.sh
```

Le script installe Apache, MariaDB et PHP 8.2 ou plus, crée la base `invoiceninja` avec un mot de passe aléatoire, télécharge la dernière archive de version, publie le dossier `public/` avec Apache et planifie les tâches de fond (étape 6). Il reste l'assistant `/setup` (étape 5), avec les informations de `/root/invoiceninja_identifiants.txt`. Variables facultatives : `NINJA_DOMAIN`, `NINJA_DB_PASS`.

## Installation manuelle

### 1. Installer Apache, MariaDB et PHP

```bash
sudo apt update
sudo apt install -y apache2 mariadb-server
sudo apt install -y php libapache2-mod-php php-mysql php-gd php-xml php-mbstring php-curl \
  php-zip php-bcmath php-gmp php-intl php-soap
php -v
```

Si la version de PHP de la distribution est inférieure à 8.2, ajouter le dépôt Sury (Debian) ou `ppa:ondrej/php` (Ubuntu).

### 2. Créer la base de données

```bash
sudo mysql -u root
```

```sql
CREATE DATABASE invoiceninja CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'ninja'@'localhost' IDENTIFIED BY 'MotDePasseFort';
GRANT ALL PRIVILEGES ON invoiceninja.* TO 'ninja'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3. Télécharger Invoice Ninja

```bash
sudo mkdir -p /var/www/invoiceninja
cd /var/www/invoiceninja
sudo wget https://github.com/invoiceninja/invoiceninja/releases/latest/download/invoiceninja.tar.gz
sudo tar -xzf invoiceninja.tar.gz
sudo rm invoiceninja.tar.gz
sudo cp .env.example .env
sudo chown -R www-data:www-data /var/www/invoiceninja
```

### 4. Créer le site Apache

```bash
sudo nano /etc/apache2/sites-available/invoiceninja.conf
```

```apache
<VirtualHost *:80>
    ServerName factures.exemple.local
    DocumentRoot /var/www/invoiceninja/public

    <Directory /var/www/invoiceninja/public>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

```bash
sudo a2enmod rewrite
sudo a2ensite invoiceninja
sudo a2dissite 000-default
sudo systemctl reload apache2
```

### 5. Assistant de configuration

Ouvrir `http://<adresse-du-serveur>/setup` et renseigner :

- l'URL de l'application ;
- la base de données (`localhost`, `invoiceninja`, `ninja`, mot de passe) ;
- les paramètres d'envoi d'e-mails (SMTP) ;
- le compte administrateur.

### 6. Planifier les tâches de fond

Les factures récurrentes et les rappels nécessitent le planificateur de Laravel :

```bash
echo '* * * * * www-data /usr/bin/php /var/www/invoiceninja/artisan schedule:run >> /dev/null 2>&1' | sudo tee /etc/cron.d/invoiceninja
```

## Vérification

Se connecter avec le compte administrateur, puis créer un client et une facture de test.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/var/www/invoiceninja/.env` | Configuration (base, URL, e-mails) |
| `/var/www/invoiceninja/storage/` | Documents, PDF, journaux |

## Dépannage

- Erreur 500 : consulter `storage/logs/laravel.log` et vérifier les droits de `www-data` sur `storage/` et `bootstrap/cache/`.

## Points d'attention

- Ne jamais lancer `php artisan migrate:fresh` sur une installation existante : cette commande efface toute la base.
- Sans serveur SMTP configuré dans l'assistant, les factures ne peuvent pas être envoyées par e-mail.
- Le script désactive le site Apache par défaut (`000-default`).
- Relu et mis à jour le 12/11/2026.

## Sources

- [Installation auto-hébergée](https://invoiceninja.github.io/en/self-host-installation/)
- [Versions publiées](https://github.com/invoiceninja/invoiceninja/releases)
