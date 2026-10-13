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

Le script demande le mot de passe de la base. Lire les points d'attention : il ne parvient plus à télécharger Invoice Ninja.

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

- Le script télécharge `https://download.invoiceninja.com/latest.zip`, qui ne répond pas (vérifié le 13/10/2026) : il s'arrête au téléchargement. Il suppose aussi un dossier `invoiceninja` dans l'archive, alors que l'archive officielle s'extrait directement dans le dossier courant.
- Il installe PHP 8.1, alors que les versions actuelles d'Invoice Ninja 5 demandent PHP 8.2.
- Il lance `php artisan migrate:fresh --seed`, qui **efface entièrement** la base avant de la recréer : à ne jamais exécuter sur une installation contenant des données.
- Il ne génère pas la clé d'application et ne planifie pas les tâches de fond. L'assistant `/setup` (étape 5) et la tâche cron (étape 6) s'en chargent.

## Sources

- [Installation auto-hébergée](https://invoiceninja.github.io/en/self-host-installation/)
- [Versions publiées](https://github.com/invoiceninja/invoiceninja/releases)
