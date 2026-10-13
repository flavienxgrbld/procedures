# Matomo — procédure d'installation

## Description

Matomo est une solution libre de mesure d'audience web, alternative à Google Analytics : les données des visiteurs restent sur son propre serveur, ce qui facilite le respect du RGPD. Cette procédure l'installe sur une pile Apache, PHP et MariaDB, puis ajoute le code de suivi à un site.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu |
| **Méthode** | Archive officielle (`matomo-latest`) |
| **Dossier** | `/var/www/matomo` |
| **Ports** | 80/tcp |
| **Script** | `install_matomo.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- Le site à mesurer, sur lequel on peut ajouter un morceau de JavaScript.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/MATOMO
sudo bash install_matomo.sh
```

Le script demande le mot de passe de la base. Lire les points d'attention : sur Debian et Ubuntu, il échoue à l'installation des modules PHP.

## Installation manuelle

### 1. Installer Apache, MariaDB et PHP

```bash
sudo apt update
sudo apt install -y apache2 mariadb-server unzip
sudo apt install -y php libapache2-mod-php php-mysql php-gd php-curl php-xml php-mbstring php-zip php-intl
```

### 2. Créer la base de données

```bash
sudo mysql -u root
```

```sql
CREATE DATABASE matomo CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER 'matomo'@'localhost' IDENTIFIED BY 'MotDePasseFort';
GRANT ALL PRIVILEGES ON matomo.* TO 'matomo'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3. Télécharger Matomo

```bash
cd /tmp
wget https://builds.matomo.org/matomo-latest.tar.gz
sudo tar -xzf matomo-latest.tar.gz -C /var/www/
sudo chown -R www-data:www-data /var/www/matomo
```

### 4. Créer le site Apache

```bash
sudo nano /etc/apache2/sites-available/matomo.conf
```

```apache
<VirtualHost *:80>
    ServerName stats.exemple.local
    DocumentRoot /var/www/matomo

    <Directory /var/www/matomo>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

```bash
sudo a2enmod rewrite
sudo a2ensite matomo
sudo a2dissite 000-default
sudo systemctl reload apache2
```

### 5. Assistant d'installation

Ouvrir `http://<adresse-du-serveur>/` et suivre les étapes : vérification du système, base de données (`localhost`, `matomo`, utilisateur `matomo`), super-utilisateur, puis premier site à suivre.

### 6. Ajouter le code de suivi

Matomo affiche un code JavaScript à coller avant la balise `</head>` de chaque page du site suivi (ou via l'extension Matomo du CMS).

### 7. Archiver les rapports par tâche planifiée

```bash
echo '5 * * * * www-data /usr/bin/php /var/www/matomo/console core:archive --url=http://stats.exemple.local/ > /dev/null' | sudo tee /etc/cron.d/matomo
```

Puis, dans *Administration → Système → Paramètres généraux*, désactiver l'archivage déclenché par le navigateur.

## Vérification

Visiter le site suivi, puis ouvrir *Visiteurs → Visites en temps réel* dans Matomo : la visite apparaît.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/var/www/matomo/config/config.ini.php` | Configuration (base, hôtes de confiance) |
| `/var/www/matomo/tmp/` | Cache et fichiers temporaires |

## Points d'attention

- Le script installe les modules PHP sous les noms `php81-mysql`, `php81-gd`, `php81-curl` et `php81-zip`. Sur Debian et Ubuntu, ce sont `php8.1-mysql`, etc. : le script s'arrête.
- Son site Apache garde le site par défaut `000-default` actif. Il indique aussi l'URL `/matomo`, alors que le site publie Matomo à la racine.
- Pour le RGPD : activer l'anonymisation des adresses IP (*Administration → Confidentialité*) permet, dans certaines conditions, de mesurer l'audience sans bandeau de consentement.

## Sources

- [Installer Matomo](https://matomo.org/faq/on-premise/installing-matomo/)
- [Archivage par tâche planifiée](https://matomo.org/faq/on-premise/how-to-set-up-auto-archiving-of-your-reports/)
