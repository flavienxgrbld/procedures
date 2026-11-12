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

Le script installe Docker s'il est absent, écrit `/opt/focalboard/compose.yaml` (volume nommé monté sur `/opt/focalboard/data`, l'emplacement des données de l'image) et démarre le conteneur. Relancé, il met l'image à jour sans toucher aux tableaux. Variable facultative : `FOCALBOARD_PORT`.

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

- Focalboard n'a plus de version officielle de Mattermost : le projet est maintenu par la communauté (organisation `mattermost-community` sur GitHub) et l'image Docker est rarement mise à jour. Pour une équipe qui utilise Mattermost, l'équivalent intégré est le module *Boards*.
- N'importe qui peut créer un compte sur la page d'accueil : limiter l'accès au réseau interne, ou passer par un proxy inverse authentifié.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Dépôt Focalboard](https://github.com/mattermost-community/focalboard)
- [Image Docker](https://hub.docker.com/r/mattermost/focalboard)
