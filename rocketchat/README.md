# Rocket.Chat — procédure d'installation

## Description

Rocket.Chat est une plateforme de messagerie d'équipe libre et auto-hébergée : canaux, messages privés, appels vidéo, partage de fichiers, intégrations et chiffrement de bout en bout. Cette procédure l'installe avec les fichiers Docker Compose officiels (Rocket.Chat, MongoDB et NATS).

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Dépôt officiel `RocketChat/rocketchat-compose` |
| **Dossier** | `/opt/rocketchat-compose` |
| **Ports** | 3000/tcp (ou 80/443 avec le proxy Traefik fourni) |
| **Script** | `install_rocketchat.sh` |

## Prérequis

- Docker et Docker Compose (procédure `docker`).
- 2 Go de RAM au minimum, 4 Go conseillés.
- Un nom de domaine pour la production (HTTPS automatique avec Traefik).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/rocketchat
sudo bash install_rocketchat.sh
```

Lire les points d'attention : si Docker n'est pas installé, le script s'arrête.

## Installation manuelle

### 1. Récupérer les fichiers officiels

```bash
cd /opt
sudo git clone --depth 1 https://github.com/RocketChat/rocketchat-compose.git
cd rocketchat-compose
sudo cp .env.example .env
```

### 2. Adapter `.env`

Renseigner au minimum :

```ini
ROOT_URL=http://<adresse-du-serveur>:3000
RELEASE=<version de Rocket.Chat souhaitée>
```

Avec un nom de domaine et HTTPS : `ROOT_URL=https://chat.exemple.fr`, `DOMAIN=chat.exemple.fr`, `LETSENCRYPT_ENABLED=true` et `LETSENCRYPT_EMAIL=admin@exemple.fr` (certificat obtenu par Traefik).

### 3. Démarrer

Sans proxy (labo) :

```bash
sudo docker compose -f compose.database.yml -f compose.yml up -d
sudo ufw allow 3000/tcp
```

Configuration complète proposée par le projet (Traefik, supervision, NATS) :

```bash
sudo docker compose -f compose.monitoring.yml -f compose.traefik.yml -f compose.database.yml -f compose.yml -f compose.nats.yml -f docker.yml up -d
```

### 4. Assistant de configuration

Ouvrir `ROOT_URL` : l'assistant crée le compte administrateur, puis demande les informations de l'organisation et l'enregistrement du serveur (facultatif pour l'édition gratuite *Starter*).

## Vérification

```bash
sudo docker compose -f compose.database.yml -f compose.yml ps
sudo docker compose -f compose.database.yml -f compose.yml logs -f rocketchat
```

## Points d'attention

- Le script appelle `$SCRIPT_DIR/../infrastructure/install_docker.sh` si Docker est absent : la variable `SCRIPT_DIR` n'est jamais définie (le script s'arrête sur « unbound variable ») et ce chemin n'existe pas dans le dépôt. Installer Docker avant (procédure `docker`).
- Son Compose utilise l'ancienne image `rocket.chat:latest` et MongoDB 5.0, qui n'est plus maintenu. Il appelle ensuite `docker-compose` (version 1), absent des installations récentes de Docker.
- Il garde `ROOT_URL: http://localhost:3000` : les liens et les notifications sont incorrects depuis un autre poste.

## Sources

- [Déployer Rocket.Chat avec Docker](https://docs.rocket.chat/docs/deploy-with-docker-docker-compose)
- [Fichiers Compose officiels](https://github.com/RocketChat/rocketchat-compose)
