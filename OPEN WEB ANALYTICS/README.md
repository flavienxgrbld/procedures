# Open Web Analytics — procédure d'installation

## Description

Open Web Analytics (OWA) est un logiciel libre de mesure d'audience web : visites, pages vues, sources de trafic, cartes de clics, avec des données hébergées sur son propre serveur. Cette procédure installe la version publiée 1.14.0 sur une pile Apache, PHP et MariaDB.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu |
| **Méthode** | Archive « packaged » officielle (GitHub) |
| **Dossier** | `/var/www/owa` |
| **Ports** | 80/tcp |
| **Script** | `install_open_web_analytics.sh` |

## Prérequis

- Apache, PHP (avec `mysqli`, `curl`, `xml`, `mbstring`) et MariaDB.
- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd "procedures/OPEN WEB ANALYTICS"
sudo bash install_open_web_analytics.sh
```

Le script installe Apache, MariaDB et PHP, crée la base `owa` (mot de passe aléatoire dans `/root/owa_identifiants.txt`), télécharge l'archive *packaged* 1.14.6 (ou `OWA_VERSION`), publie OWA à la racine du site et désactive le site par défaut. Il reste l'assistant `install.php`. Variable facultative : `OWA_DOMAIN`.

## Installation manuelle

### 1. Installer Apache, MariaDB et PHP

```bash
sudo apt update
sudo apt install -y apache2 mariadb-server
sudo apt install -y php libapache2-mod-php php-mysql php-curl php-xml php-mbstring php-gd
```

### 2. Créer la base de données

```bash
sudo mysql -u root
```

```sql
CREATE DATABASE owa CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'owa'@'localhost' IDENTIFIED BY 'MotDePasseFort';
GRANT ALL PRIVILEGES ON owa.* TO 'owa'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3. Télécharger OWA

Utiliser l'archive *packaged*, qui contient les dépendances :

```bash
cd /tmp
wget https://github.com/Open-Web-Analytics/Open-Web-Analytics/releases/download/1.14.6/owa_1.14.6_packaged.tar
sudo mkdir -p /var/www/owa
sudo tar -xf owa_1.14.6_packaged.tar -C /var/www/owa
sudo chown -R www-data:www-data /var/www/owa
```

### 4. Créer le site Apache

```bash
sudo nano /etc/apache2/sites-available/owa.conf
```

```apache
<VirtualHost *:80>
    ServerName stats.exemple.local
    DocumentRoot /var/www/owa

    <Directory /var/www/owa>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

```bash
sudo a2enmod rewrite
sudo a2ensite owa
sudo a2dissite 000-default
sudo systemctl reload apache2
```

### 5. Lancer l'installateur

Ouvrir `http://<adresse-du-serveur>/install.php` : renseigner la base (`localhost`, `owa`, utilisateur `owa`), l'URL publique d'OWA, puis le compte administrateur. L'installateur crée `owa-config.php`.

### 6. Ajouter le site à suivre

Dans OWA, *Administration → Sites → Add a site*, puis copier le code de suivi JavaScript dans les pages du site.

## Vérification

Visiter le site suivi, puis consulter le tableau de bord d'OWA : la visite apparaît après le traitement des données.

## Points d'attention

- OWA évolue peu : pour un nouveau projet, Matomo (procédure `MATOMO`) ou Plausible (procédure `PLAUSIBLE`) sont plus actifs.
- Utiliser l'archive *packaged* : l'archive du code source ne contient pas les dépendances.
- Supprimer `install.php` une fois l'installation terminée.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Dépôt Open Web Analytics](https://github.com/Open-Web-Analytics/Open-Web-Analytics)
- [Wiki d'installation](https://github.com/Open-Web-Analytics/Open-Web-Analytics/wiki/Installation)
