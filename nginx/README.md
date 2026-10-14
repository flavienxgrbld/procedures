# Nginx — procédure d'installation

## Description

Nginx est un serveur web et un proxy inverse très performant et peu gourmand. Il sert des sites statiques, des applications PHP (via PHP-FPM) et sert de point d'entrée HTTPS devant d'autres services (Node.js, conteneurs Docker…). Cette procédure l'installe, crée un site et configure un proxy inverse.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu, RHEL/Fedora, openSUSE, Arch |
| **Méthode** | Paquets de la distribution |
| **Ports** | 80/tcp (HTTP), 443/tcp (HTTPS) |
| **Script** | `install_nginx.sh` |

## Prérequis

- Un accès root.
- Aucun autre service sur les ports 80 et 443 (Apache par exemple).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/nginx
sudo bash install_nginx.sh
```

## Installation manuelle

### 1. Installer et démarrer

```bash
sudo apt update
sudo apt install -y nginx
sudo systemctl enable --now nginx
sudo ufw allow 'Nginx Full'
```

### 2. Créer un site statique

```bash
sudo mkdir -p /var/www/monsite
echo "<h1>Ça marche</h1>" | sudo tee /var/www/monsite/index.html
sudo nano /etc/nginx/sites-available/monsite
```

```nginx
server {
    listen 80;
    server_name monsite.exemple.local;
    root /var/www/monsite;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/monsite /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 3. Proxy inverse vers une application

Pour publier une application qui écoute sur le port 3000 :

```nginx
server {
    listen 80;
    server_name app.exemple.local;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSockets
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### 4. Passer en HTTPS

Avec un nom de domaine public : `sudo certbot --nginx -d app.exemple.fr` (procédure `certbot`).

## Vérification

```bash
systemctl status nginx
sudo nginx -t
curl -I http://localhost
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/nginx/nginx.conf` | Configuration principale |
| `/etc/nginx/sites-available/` | Sites disponibles |
| `/etc/nginx/sites-enabled/` | Sites actifs (liens symboliques) |
| `/var/log/nginx/` | Journaux d'accès et d'erreurs |

## Dépannage

- Toujours lancer `sudo nginx -t` avant `reload` : une erreur de syntaxe empêche le rechargement.
- **502 Bad Gateway** : l'application derrière le proxy ne répond pas sur le port indiqué.
- Erreurs : `sudo tail -f /var/log/nginx/error.log`.

## Points d'attention

- Les dossiers `sites-available` et `sites-enabled` indiqués par le script n'existent que sur Debian et Ubuntu. Sur RHEL, Fedora et Arch, les sites se déclarent dans `/etc/nginx/conf.d/*.conf`.
- Le script n'ouvre les ports que si `ufw` est présent. Avec `firewalld` : `sudo firewall-cmd --permanent --add-service={http,https} && sudo firewall-cmd --reload`.

## Sources

- [Documentation Nginx](https://nginx.org/en/docs/)
- [Guide du débutant](https://nginx.org/en/docs/beginners_guide.html)
