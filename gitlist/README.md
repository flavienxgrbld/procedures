# GitList — procédure d'installation

## Description

GitList est une interface web en lecture seule pour parcourir des dépôts Git hébergés sur un serveur : arborescence, historique des commits, différences, blame, branches et étiquettes. Cette procédure installe la version stable 2.0.1 sur Apache et PHP.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu |
| **Méthode** | Archive officielle (GitHub) |
| **Dossier** | `/var/www/gitlist` (racine web : `public/`) |
| **Ports** | 80/tcp |
| **Script** | `install_gitlist.sh` |

## Prérequis

- PHP 8.1 ou plus récent, avec les extensions `xml` et `mbstring`.
- Git 2.
- Des dépôts Git présents sur le serveur (ici dans `/srv/git`).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/gitlist
sudo bash install_gitlist.sh
```

Lire les points d'attention : le script ne parvient plus à télécharger GitList.

## Installation manuelle

### 1. Installer Apache, PHP et Git

```bash
sudo apt update
sudo apt install -y apache2 php libapache2-mod-php php-xml php-mbstring git unzip
```

### 2. Télécharger GitList

Utiliser l'archive de la version publiée, pas le code source :

```bash
cd /tmp
wget https://github.com/klaussilveira/gitlist/releases/download/2.0.1/gitlist-2.0.1.zip
sudo mkdir -p /var/www/gitlist
sudo unzip gitlist-2.0.1.zip -d /var/www/gitlist
```

### 3. Indiquer l'emplacement des dépôts

Dans `/var/www/gitlist/config/config.yml` :

```yaml
  default_repository_dir: /srv/git
```

Le serveur web doit pouvoir lire ce dossier :

```bash
sudo chmod -R o+rX /srv/git
```

### 4. Créer les dossiers de cache et de journaux

```bash
cd /var/www/gitlist
sudo mkdir -p var/cache var/log
sudo chown -R www-data:www-data var
```

### 5. Créer le site Apache

```bash
sudo nano /etc/apache2/sites-available/gitlist.conf
```

```apache
<VirtualHost *:80>
    ServerName git.exemple.local
    DocumentRoot /var/www/gitlist/public

    <Directory /var/www/gitlist/public>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

```bash
sudo a2enmod rewrite
sudo a2ensite gitlist
sudo a2dissite 000-default
sudo systemctl reload apache2
```

## Vérification

Ouvrir `http://<adresse-du-serveur>/` : la liste des dépôts de `/srv/git` s'affiche.

## Dépannage

- **Liste vide** : le chemin `default_repository_dir` est incorrect, ou `www-data` ne peut pas lire les dépôts.
- **Erreur « dubious ownership »** de Git : déclarer les dépôts comme sûrs pour `www-data`, avec `sudo -u www-data git config --global --add safe.directory '*'`.
- Journaux : `/var/www/gitlist/var/log/` et `/var/log/apache2/error.log`.

## Points d'attention

- Le script télécharge `github.com/dlhsmp/GitList/archive/master.zip`, qui n'existe pas (erreur 404, vérifié le 13/10/2026) : il s'arrête au téléchargement. Le projet officiel est `klaussilveira/gitlist`.
- Même avec le bon dépôt, l'archive du code source ne convient pas : le projet demande d'utiliser l'archive de version (`gitlist-<version>.zip`), qui contient les dépendances.
- Le script ne configure pas l'emplacement des dépôts et garde le site Apache par défaut `000-default` actif.
- GitList ne gère ni comptes ni droits : le protéger (authentification Apache, réseau interne) si les dépôts sont privés.

## Sources

- [Dépôt GitList](https://github.com/klaussilveira/gitlist)
- [Versions publiées](https://github.com/klaussilveira/gitlist/releases)
