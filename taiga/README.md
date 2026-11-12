# Taiga — procédure d'installation

## Description

Taiga est une plateforme libre de gestion de projets agiles : tableaux Kanban, Scrum (backlog, sprints, user stories), tickets, wiki et rapports d'avancement. Cette procédure l'installe avec le dépôt officiel `taiga-docker`.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Dépôt officiel `taigaio/taiga-docker` (back, front, événements, PostgreSQL, RabbitMQ) |
| **Dossier** | `/opt/taiga-docker` |
| **Ports** | 9000/tcp |
| **Script** | `install_taiga.sh` |

## Prérequis

- Docker et Docker Compose (procédure `docker`).
- 2 Go de RAM au minimum.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/taiga
sudo bash install_taiga.sh
```

Le script installe Docker s'il est absent, récupère `taiga-docker` (branche `stable`), règle `.env` (adresse du serveur, clé secrète et mots de passe PostgreSQL/RabbitMQ aléatoires), démarre Taiga avec `launch-taiga.sh` puis crée le super-utilisateur `admin` sans question (mot de passe dans `/root/taiga_identifiants.txt`). Variables facultatives : `TAIGA_DOMAIN`, `TAIGA_ADMIN_EMAIL`.

## Installation manuelle

### 1. Récupérer le dépôt officiel

```bash
cd /opt
sudo git clone https://github.com/taigaio/taiga-docker.git
cd taiga-docker
sudo git checkout stable
```

### 2. Adapter `.env`

```ini
TAIGA_SCHEME=http
TAIGA_DOMAIN=<adresse-du-serveur>:9000
SUBPATH=""
WEBSOCKETS_SCHEME=ws

SECRET_KEY="<chaîne aléatoire : openssl rand -hex 32>"

POSTGRES_USER=taiga
POSTGRES_PASSWORD=MotDePasseBase

EMAIL_BACKEND=console
```

Pour l'envoi d'e-mails (invitations, notifications), passer `EMAIL_BACKEND=smtp` et renseigner les variables `EMAIL_*` du fichier. Changer aussi les mots de passe RabbitMQ (`RABBITMQ_*`).

### 3. Démarrer

```bash
sudo ./launch-taiga.sh
sudo ufw allow 9000/tcp
```

### 4. Créer le super-utilisateur

```bash
sudo ./taiga-manage.sh createsuperuser
```

### 5. Se connecter

Ouvrir `http://<adresse-du-serveur>:9000`, se connecter avec le super-utilisateur, puis créer un projet (modèle Scrum ou Kanban).

## Vérification

```bash
sudo docker compose ps
sudo docker compose logs -f taiga-back
```

## Points d'attention

- Les e-mails sont désactivés (`EMAIL_BACKEND=console`) : pour les invitations et notifications, configurer les variables `EMAIL_*` de `.env`.
- Pour la production, publier Taiga derrière Nginx en HTTPS (procédures `nginx` et `certbot`) et passer `TAIGA_SCHEME=https` et `WEBSOCKETS_SCHEME=wss`.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Installer Taiga en production](https://docs.taiga.io/setup-production.html)
- [Dépôt taiga-docker](https://github.com/taigaio/taiga-docker)
