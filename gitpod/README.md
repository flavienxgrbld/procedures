# Gitpod / OpenVSCode Server — procédure

## Description

Gitpod fournit des environnements de développement prêts à l'emploi dans le navigateur. Sa version auto-hébergée n'est plus distribuée : cette procédure installe à la place OpenVSCode Server, publié par l'équipe Gitpod, qui donne un VS Code complet dans le navigateur sur son propre serveur.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Image Docker `gitpod/openvscode-server` |
| **Ports** | 3000/tcp |
| **Script** | `install_gitpod.sh` (voir les points d'attention) |

## Prérequis

- Docker installé (voir la procédure `docker`).
- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/gitpod
sudo bash install_gitpod.sh
```

Le script installe Docker s'il est absent, prépare `/opt/openvscode/workspace`, génère un jeton de connexion (enregistré dans `/opt/openvscode/.env`), écrit le `compose.yaml` de l'étape 2 et démarre le conteneur. Variables facultatives : `OVS_PORT`, `OVS_TOKEN`.

## Installation manuelle

### 1. Préparer le dossier de travail

```bash
sudo mkdir -p /opt/openvscode/workspace
cd /opt/openvscode
```

### 2. Décrire le service

`/opt/openvscode/compose.yaml` :

```yaml
services:
  openvscode:
    image: gitpod/openvscode-server:latest
    container_name: openvscode
    restart: unless-stopped
    ports:
      - "3000:3000"
    command: --host 0.0.0.0 --connection-token MonJetonSecret
    volumes:
      - ./workspace:/home/workspace
```

Le jeton de connexion (`--connection-token`) protège l'accès : sans lui, n'importe qui sur le réseau peut utiliser l'éditeur et le terminal.

### 3. Démarrer

```bash
sudo chown -R 1000:1000 /opt/openvscode/workspace
sudo docker compose up -d
sudo ufw allow 3000/tcp
```

### 4. Se connecter

Ouvrir `http://<adresse-du-serveur>:3000/?tkn=MonJetonSecret`. Le dossier `/home/workspace` du conteneur correspond à `/opt/openvscode/workspace` sur le serveur.

## Vérification

```bash
sudo docker compose ps
sudo docker compose logs openvscode
```

## Dépannage

- Fichiers non modifiables : le conteneur tourne avec l'utilisateur d'UID 1000, qui doit être propriétaire du dossier `workspace` (étape 3).
- Mise à jour : `sudo docker compose pull && sudo docker compose up -d`.

## Points d'attention

- Le jeton donne accès à un terminal dans le conteneur et à tous les fichiers du dossier `workspace` : ne pas le partager, et le changer (`OVS_TOKEN` dans `.env`, puis `docker compose up -d`) s'il a circulé.
- Pour un accès depuis Internet, placer le service derrière un proxy inverse avec HTTPS (Nginx et `certbot`) : certaines fonctions de VS Code (presse-papiers, webviews) exigent HTTPS.
- Relu et mis à jour le 12/11/2026 (OpenVSCode Server 1.109).

## Sources

- [OpenVSCode Server](https://github.com/gitpod-io/openvscode-server)
