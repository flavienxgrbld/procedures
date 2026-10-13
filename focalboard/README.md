# Focalboard — procédure d'installation

## Description

Focalboard est un outil libre de gestion de projets et de tâches en tableaux (kanban, tables, galeries, calendrier), alternative auto-hébergée à Trello, Notion ou Asana. Cette procédure installe la version serveur autonome avec l'image Docker officielle.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Image Docker `mattermost/focalboard` |
| **Ports** | 8000/tcp |
| **Script** | `install_focalboard.sh` |

## Prérequis

- Docker installé (voir la procédure `docker`).
- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/focalboard
sudo bash install_focalboard.sh
```

Le script installe `docker.io`, puis démarre le conteneur `focalboard` sur le port 8000.

## Installation manuelle

### 1. Créer le dossier du service

```bash
sudo mkdir -p /opt/focalboard
cd /opt/focalboard
```

### 2. Décrire le service

`/opt/focalboard/compose.yaml` :

```yaml
services:
  focalboard:
    image: mattermost/focalboard:latest
    container_name: focalboard
    restart: unless-stopped
    ports:
      - "8000:8000"
    volumes:
      - focalboard_data:/opt/focalboard/data

volumes:
  focalboard_data:
```

### 3. Démarrer

```bash
sudo docker compose up -d
sudo ufw allow 8000/tcp
```

### 4. Première connexion

Ouvrir `http://<adresse-du-serveur>:8000` et créer un compte avec le lien d'inscription (*Register*), puis créer un premier tableau à partir d'un modèle.

## Vérification

```bash
sudo docker compose ps
sudo docker compose logs focalboard
curl -I http://localhost:8000
```

## Sauvegarde

Les données (base SQLite et fichiers joints) se trouvent dans le volume `focalboard_data` :

```bash
sudo docker run --rm -v focalboard_focalboard_data:/data -v "$PWD":/backup alpine tar czf /backup/focalboard.tgz -C /data .
```

## Dépannage

- Mise à jour : `sudo docker compose pull && sudo docker compose up -d`.
- Après une mise à jour, vérifier avec `docker compose logs` que la base a bien été migrée.

## Points d'attention

- Le script monte son volume sur `/data` dans le conteneur, alors que l'image enregistre ses données dans `/opt/focalboard/data` (d'après le `Dockerfile` officiel). Les tableaux finissent dans un volume anonyme et sont perdus si le conteneur est recréé. Il crée aussi le volume après avoir démarré le conteneur, ce qui est inutile car Docker le crée automatiquement.
- Le script affiche des identifiants par défaut (`admin@example.com` / `Password1!`) qui ne figurent pas dans la documentation du projet : à la première visite, il faut créer son compte.
- Focalboard est maintenu par la communauté (organisation `mattermost-community` sur GitHub). Pour une équipe qui utilise déjà Mattermost, l'équivalent intégré est le module *Boards*.

## Sources

- [Dépôt Focalboard](https://github.com/mattermost-community/focalboard)
- [Image Docker](https://hub.docker.com/r/mattermost/focalboard)
