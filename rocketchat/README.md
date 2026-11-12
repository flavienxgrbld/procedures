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

Le script installe Docker s'il est absent, récupère le dépôt officiel `rocketchat-compose` dans `/opt`, crée `.env` à partir de l'exemple officiel avec `ROOT_URL` = adresse du serveur (ou `RC_ROOT_URL`), puis démarre la configuration sans proxy (`compose.database.yml` + `compose.yml`) sur le port 3000. Variable facultative : `RC_RELEASE` (version de Rocket.Chat).

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

- `ROOT_URL` doit être l'adresse exacte utilisée par les utilisateurs : avec `localhost`, les liens et les notifications sont faux.
- Pour un accès depuis Internet, utiliser la configuration avec Traefik et Let's Encrypt (étape 3) ou un proxy inverse HTTPS.
- Créer le compte administrateur dès la première visite : l'assistant est accessible à tous tant qu'il n'est pas terminé.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Déployer Rocket.Chat avec Docker](https://docs.rocket.chat/docs/deploy-with-docker-docker-compose)
- [Fichiers Compose officiels](https://github.com/RocketChat/rocketchat-compose)
