# DokuWiki — procédure d'installation

## Description

DokuWiki est un wiki simple et léger qui stocke ses pages dans des fichiers texte, sans base de données. Il convient bien à une documentation technique interne. Cette procédure l'installe sur Apache et PHP.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu |
| **Méthode** | Archive officielle (version stable) |
| **Dossier** | `/var/www/dokuwiki` |
| **Ports** | 80/tcp |
| **Script** | `install_dokuwiki.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- Aucune base de données nécessaire.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/dokuwiki
sudo bash install_dokuwiki.sh
```

Le script installe Apache et PHP, télécharge la version stable officielle (`dokuwiki-stable.tgz`) dans `/var/www/dokuwiki`, crée le site Apache de l'étape 3 (accès aux dossiers `data`, `conf`… interdit) et désactive le site par défaut. Il reste à lancer l'assistant (étape 4) puis à supprimer `install.php` (étape 5). Variable facultative : `DOKUWIKI_DOMAIN`.

## Installation manuelle

### 1. Installer Apache et PHP

```bash
sudo apt update
sudo apt install -y apache2 php libapache2-mod-php php-xml php-mbstring php-gd php-intl php-zip
```

### 2. Télécharger DokuWiki

```bash
cd /tmp
wget https://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz
sudo mkdir -p /var/www/dokuwiki
sudo tar -xzf dokuwiki-stable.tgz -C /var/www/dokuwiki --strip-components=1
sudo chown -R www-data:www-data /var/www/dokuwiki
```

### 3. Créer le site Apache

```bash
sudo nano /etc/apache2/sites-available/dokuwiki.conf
```

```apache
<VirtualHost *:80>
    ServerName wiki.exemple.local
    DocumentRoot /var/www/dokuwiki

    <Directory /var/www/dokuwiki>
        AllowOverride All
        Require all granted
    </Directory>

    # Interdire l'accès direct aux dossiers sensibles
    <LocationMatch "/(data|conf|bin|inc|vendor)/">
        Require all denied
    </LocationMatch>
</VirtualHost>
```

```bash
sudo a2enmod rewrite
sudo a2ensite dokuwiki
sudo a2dissite 000-default
sudo systemctl reload apache2
```

### 4. Lancer l'assistant d'installation

Ouvrir `http://<adresse-du-serveur>/install.php`, puis renseigner le nom du wiki, le compte super-utilisateur et la politique d'accès (ACL), par exemple « wiki fermé » pour une documentation interne.

### 5. Supprimer le fichier d'installation

```bash
sudo rm /var/www/dokuwiki/install.php
```

## Vérification

```bash
curl -I http://localhost/doku.php
```

Le wiki s'affiche sur `http://<adresse-du-serveur>/` et la connexion avec le super-utilisateur fonctionne.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/var/www/dokuwiki/data/pages/` | Pages du wiki (fichiers `.txt`) |
| `/var/www/dokuwiki/data/media/` | Images et fichiers joints |
| `/var/www/dokuwiki/conf/` | Configuration, utilisateurs, ACL |

Sauvegarder les dossiers `data/` et `conf/` suffit à sauvegarder le wiki.

## Dépannage

- **Avertissement « data directory not protected »** : la section `LocationMatch` ou `AllowOverride All` manque.
- **Erreur d'écriture** : `www-data` doit être propriétaire de `data/` et `conf/`.

## Points d'attention

- Tant que `install.php` existe, n'importe qui peut relancer l'assistant et prendre le contrôle du wiki : le supprimer juste après l'installation (le script le rappelle).
- Les pages sont des fichiers texte dans `data/` : sauvegarder ce dossier (et `conf/`) suffit à sauvegarder le wiki.
- Le script désactive le site Apache par défaut (`000-default`) : le wiki répond sur l'adresse IP du serveur.
- Relu et mis à jour le 12/11/2026 (version stable 2026-07-14).

## Sources

- [Installer DokuWiki](https://www.dokuwiki.org/install)
- [Sécuriser DokuWiki](https://www.dokuwiki.org/security)
