# Matrix Synapse — procédure d'installation

## Description

Matrix est un protocole ouvert de messagerie instantanée décentralisée et chiffrée de bout en bout. Synapse est son serveur de référence : il héberge les comptes et les salons et communique avec les autres serveurs Matrix. Cette procédure installe Synapse depuis le dépôt officiel, avec PostgreSQL et Nginx, pour une utilisation avec le client Element.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu |
| **Méthode** | Dépôt officiel `packages.matrix.org` (paquet `matrix-synapse-py3`) |
| **Ports** | 443/tcp (clients, via Nginx), 8448/tcp (fédération) ; Synapse écoute en interne sur 8008 |
| **Script** | `install_matrix_synapse.sh` |

## Prérequis

- Un **nom de domaine** (ici `matrix.exemple.fr`) pointant vers le serveur.
- Nginx et Certbot (procédures `nginx` et `certbot`).
- 2 Go de RAM au minimum.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/matrix_synapse
sudo MATRIX_SERVER_NAME=matrix.exemple.fr MATRIX_EMAIL=admin@exemple.fr bash install_matrix_synapse.sh
```

Le script ajoute le dépôt Matrix, installe Synapse avec le nom de serveur indiqué (sans question), crée la base PostgreSQL (mot de passe aléatoire) et l'indique dans `homeserver.yaml` avec un `registration_shared_secret`. Avec `MATRIX_EMAIL`, il publie aussi Synapse derrière Nginx en HTTPS, y compris sur le port de fédération 8448 (étape 4). Il reste à créer le compte administrateur (étape 5).

## Installation manuelle

### 1. Ajouter le dépôt Matrix et installer Synapse

```bash
sudo apt update
sudo apt install -y lsb-release wget apt-transport-https
sudo wget -O /usr/share/keyrings/matrix-org-archive-keyring.gpg https://packages.matrix.org/debian/matrix-org-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/matrix-org-archive-keyring.gpg] https://packages.matrix.org/debian/ $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/matrix-org.list
sudo apt update
sudo apt install -y matrix-synapse-py3
```

À l'installation, indiquer le **nom du serveur** : `matrix.exemple.fr`. Il apparaîtra dans les identifiants (`@alice:matrix.exemple.fr`) et ne peut plus être changé.

### 2. Créer la base PostgreSQL

```bash
sudo apt install -y postgresql
sudo -u postgres createuser --pwprompt synapse_user
sudo -u postgres createdb --encoding=UTF8 --locale=C --template=template0 --owner=synapse_user synapse
```

Dans `/etc/matrix-synapse/homeserver.yaml`, remplacer la section `database` :

```yaml
database:
  name: psycopg2
  args:
    user: synapse_user
    password: MotDePasseFort
    dbname: synapse
    host: localhost
    cp_min: 5
    cp_max: 10
```

### 3. Préparer l'inscription des comptes

Ajouter dans `homeserver.yaml` un secret pour créer les comptes en ligne de commande :

```yaml
registration_shared_secret: "<chaîne aléatoire longue>"
```

```bash
sudo systemctl restart matrix-synapse
```

### 4. Publier derrière Nginx en HTTPS

`/etc/nginx/sites-available/matrix` :

```nginx
server {
    listen 80;
    server_name matrix.exemple.fr;

    location ~ ^(/_matrix|/_synapse/client) {
        proxy_pass http://127.0.0.1:8008;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;
        client_max_body_size 50M;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/matrix /etc/nginx/sites-enabled/
sudo certbot --nginx -d matrix.exemple.fr
sudo ufw allow 443/tcp
sudo ufw allow 8448/tcp
```

Pour la fédération sur le port 8448, ajouter à ce site un bloc `listen 8448 ssl;` avec le même certificat.

### 5. Créer un compte administrateur

```bash
register_new_matrix_user -c /etc/matrix-synapse/homeserver.yaml http://localhost:8008
```

### 6. Se connecter

Avec Element (application ou `app.element.io`), choisir « serveur personnalisé » : `https://matrix.exemple.fr`.

## Vérification

```bash
systemctl status matrix-synapse
curl -s https://matrix.exemple.fr/_matrix/client/versions | head -c 200
```

Le testeur de fédération (`federationtester.matrix.org`) vérifie que les autres serveurs peuvent joindre le vôtre.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/matrix-synapse/homeserver.yaml` | Configuration |
| `/etc/matrix-synapse/conf.d/server_name.yaml` | Nom du serveur |
| `/var/lib/matrix-synapse/` | Médias et clés de signature |
| `/var/log/matrix-synapse/` | Journaux |

## Points d'attention

- Le **nom du serveur** fait partie de tous les identifiants (`@alice:matrix.exemple.fr`) et ne peut plus être changé après l'installation.
- Synapse fonctionne avec PostgreSQL (ou SQLite pour un test) : MariaDB/MySQL n'est pas pris en charge.
- L'inscription libre est désactivée par défaut : les comptes se créent avec `register_new_matrix_user`.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Installer Synapse](https://element-hq.github.io/synapse/latest/setup/installation.html)
- [Configurer le proxy inverse](https://element-hq.github.io/synapse/latest/reverse_proxy.html)
