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

Le script installe Apache, PHP et Git, télécharge l'archive de version 2.0.1, indique le dossier des dépôts (`/srv/git` ou `GITLIST_REPOS`), prépare le cache et publie le dossier `public/` avec Apache. Pour protéger l'accès par mot de passe (recommandé) :

```bash
sudo GITLIST_USER=lecteur GITLIST_PASS=MotDePasseFort bash install_gitlist.sh
```

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

Le serveur web doit pouvoir lire ce dossier, et Git doit accepter des dépôts appartenant à un autre utilisateur que `www-data` :

```bash
sudo chmod -R o+rX /srv/git
sudo git config --system --add safe.directory '*'
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

- GitList ne gère ni comptes ni droits : sans `GITLIST_USER`/`GITLIST_PASS` (authentification Apache), tous les dépôts du dossier sont visibles par quiconque accède au serveur.
- La dernière version publiée avec son archive d'installation est la 2.0.1 (le tag 2.0.2 n'a pas d'archive). Ne pas utiliser l'archive du code source, qui ne contient pas les dépendances.
- Le script désactive le site Apache par défaut (`000-default`).
- Relu et mis à jour le 12/11/2026.

## Sources

- [Dépôt GitList](https://github.com/klaussilveira/gitlist)
- [Versions publiées](https://github.com/klaussilveira/gitlist/releases)
