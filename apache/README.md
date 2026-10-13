# Apache — procédure d'installation

## Description

Apache HTTP Server est le serveur web libre le plus répandu. Il sert des sites statiques ou dynamiques (PHP) et peut faire office de proxy inverse. Cette procédure installe Apache depuis les dépôts de la distribution et ouvre les ports HTTP et HTTPS.

| | |
|---|---|
| **Systèmes** | Debian/Ubuntu (`apache2`), RHEL/Fedora (`httpd`), openSUSE, Arch |
| **Méthode** | Paquets de la distribution |
| **Ports** | 80/tcp (HTTP), 443/tcp (HTTPS) |
| **Script** | `install_apache.sh` |

## Prérequis

- Un accès root (`sudo`) et une connexion Internet.
- Aucun autre service n'écoutant déjà sur les ports 80 et 443 (Nginx par exemple).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/apache
sudo bash install_apache.sh
```

## Installation manuelle

### 1. Installer le paquet

```bash
sudo apt update
sudo apt install -y apache2 apache2-utils
```

Sur RHEL/Fedora : `sudo dnf install -y httpd httpd-tools` (le service s'appelle alors `httpd`).

### 2. Démarrer le service au boot

```bash
sudo systemctl enable --now apache2
```

### 3. Ouvrir le pare-feu

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### 4. Créer un site (hôte virtuel)

```bash
sudo mkdir -p /var/www/monsite
echo "<h1>Ça marche</h1>" | sudo tee /var/www/monsite/index.html
sudo nano /etc/apache2/sites-available/monsite.conf
```

```apache
<VirtualHost *:80>
    ServerName monsite.exemple.local
    DocumentRoot /var/www/monsite
    ErrorLog ${APACHE_LOG_DIR}/monsite_error.log
    CustomLog ${APACHE_LOG_DIR}/monsite_access.log combined
</VirtualHost>
```

```bash
sudo a2ensite monsite
sudo apache2ctl configtest
sudo systemctl reload apache2
```

### 5. (Optionnel) Activer HTTPS

Avec un nom de domaine public, utiliser la procédure `certbot`. Sinon, activer le module SSL avec un certificat autosigné :

```bash
sudo a2enmod ssl
sudo a2ensite default-ssl
sudo systemctl reload apache2
```

## Vérification

```bash
systemctl status apache2
apache2 -v
curl -I http://localhost
```

La page par défaut « Apache2 Debian Default Page » doit s'afficher sur `http://<adresse-du-serveur>`.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/apache2/apache2.conf` | Configuration principale |
| `/etc/apache2/sites-available/` | Sites disponibles (`a2ensite` / `a2dissite`) |
| `/etc/apache2/mods-available/` | Modules (`a2enmod` / `a2dismod`) |
| `/var/www/` | Racine des sites |
| `/var/log/apache2/` | Journaux d'accès et d'erreurs |

## Dépannage

- Tester la syntaxe avant de recharger : `sudo apache2ctl configtest`.
- Port déjà utilisé : `sudo ss -tlnp | grep ':80'`.
- Erreurs : `sudo tail -f /var/log/apache2/error.log`.

## Points d'attention

- Les chemins affichés en fin de script (`/etc/apache2/...`) valent pour Debian et Ubuntu. Sur RHEL/Fedora, la configuration se trouve dans `/etc/httpd/`.
- Le script ouvre les ports uniquement si `ufw` est installé. Avec `firewalld`, lancer `sudo firewall-cmd --permanent --add-service={http,https} && sudo firewall-cmd --reload`.

## Sources

- [Documentation Apache 2.4](https://httpd.apache.org/docs/2.4/fr/)
- [Apache sur Debian (wiki)](https://wiki.debian.org/Apache)
