# Outline — procédure d'installation

## Description

Outline est un wiki et une base de connaissances d'équipe, rapide et collaboratif : édition à plusieurs en temps réel, collections, recherche, intégrations (Slack, Figma…). Cette procédure le déploie avec Docker Compose (Outline, PostgreSQL, Redis), avec connexion par lien magique envoyé par e-mail.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Image officielle `outlinewiki/outline` + PostgreSQL + Redis |
| **Dossier** | `/opt/outline` |
| **Ports** | 3000/tcp (à publier derrière un proxy HTTPS) |
| **Script** | `install_outline.sh` |

## Prérequis

- Docker et Docker Compose (procédure `docker`).
- Un **nom de domaine** et HTTPS (proxy inverse Nginx et `certbot`).
- Un moyen de connexion : **serveur SMTP** (lien magique par e-mail) ou fournisseur d'identité OIDC (Keycloak, Google, Microsoft…). Outline n'a pas de mot de passe local.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/outline
sudo bash install_outline.sh
```

Lire les points d'attention : sans méthode de connexion ni secrets valides, personne ne peut se connecter.

## Installation manuelle

### 1. Préparer le dossier et les secrets

```bash
sudo mkdir -p /opt/outline/data
cd /opt/outline
openssl rand -hex 32     # SECRET_KEY
openssl rand -hex 32     # UTILS_SECRET
sudo chown 1001:1001 /opt/outline/data
```

### 2. Écrire le fichier `.env`

`/opt/outline/.env` :

```ini
NODE_ENV=production
URL=https://wiki.exemple.fr
PORT=3000
SECRET_KEY=<première valeur générée>
UTILS_SECRET=<seconde valeur générée>

DATABASE_URL=postgres://outline:MotDePasseBase@postgres:5432/outline
PGSSLMODE=disable
REDIS_URL=redis://redis:6379

FILE_STORAGE=local
FILE_STORAGE_LOCAL_ROOT_DIR=/var/lib/outline/data

# Connexion par lien magique envoyé par e-mail
SMTP_HOST=smtp.exemple.fr
SMTP_PORT=587
SMTP_USERNAME=wiki@exemple.fr
SMTP_PASSWORD=MotDePasseSmtp
SMTP_FROM_EMAIL=wiki@exemple.fr
```

### 3. Décrire les services

`/opt/outline/compose.yaml` :

```yaml
services:
  outline:
    image: outlinewiki/outline:latest
    restart: unless-stopped
    env_file: .env
    ports:
      - "127.0.0.1:3000:3000"
    volumes:
      - ./data:/var/lib/outline/data
    depends_on: [postgres, redis]

  postgres:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_USER: outline
      POSTGRES_PASSWORD: MotDePasseBase
      POSTGRES_DB: outline
    volumes:
      - pg_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    restart: unless-stopped

volumes:
  pg_data:
```

### 4. Démarrer et publier en HTTPS

```bash
sudo docker compose up -d
```

Créer un site Nginx qui renvoie `wiki.exemple.fr` vers `http://127.0.0.1:3000`, avec la prise en charge des WebSockets (modèle dans la procédure `nginx`), puis `sudo certbot --nginx -d wiki.exemple.fr`.

### 5. Première connexion

Ouvrir `https://wiki.exemple.fr`, saisir son adresse e-mail et cliquer sur le lien reçu. Le premier compte devient administrateur de l'espace de travail.

## Vérification

```bash
sudo docker compose ps
sudo docker compose logs -f outline
```

## Points d'attention

- Le Compose du script garde les secrets d'exemple (`your-secret-key`) et ne configure aucune méthode de connexion : la page d'accueil n'offre aucun moyen de se connecter.
- Il ne définit ni stockage des fichiers ni `PGSSLMODE=disable` : avec PostgreSQL local sans SSL, Outline refuse la connexion à la base.
- Il utilise `URL: http://localhost:3000` : les liens et la connexion ne fonctionnent pas depuis un autre poste.

## Sources

- [Héberger Outline avec Docker](https://docs.getoutline.com/s/hosting/doc/docker-7pfeLP5a8t)
- [Dépôt Outline](https://github.com/outline/outline)
