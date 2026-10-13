# Portainer — procédure d'installation

## Description

Portainer est une interface web pour administrer Docker (et Kubernetes) : conteneurs, images, volumes, réseaux, piles Docker Compose, journaux et console, sans passer par la ligne de commande. Cette procédure installe Portainer Community Edition dans un conteneur.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Image officielle `portainer/portainer-ce` |
| **Ports** | 9443/tcp (interface HTTPS), 8000/tcp (tunnel pour les agents Edge) |
| **Script** | `install_portainer.sh` |

## Prérequis

- **Docker installé** (procédure `docker`) : le script ne l'installe pas.
- Un accès root.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/portainer
sudo bash install_portainer.sh
```

## Installation manuelle

### 1. Créer le volume de données

```bash
sudo docker volume create portainer_data
```

### 2. Démarrer Portainer

```bash
sudo docker run -d \
  -p 9443:9443 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:lts
```

Ajouter `-p 8000:8000` uniquement si l'on gère des machines distantes avec des agents *Edge*.

### 3. Ouvrir le pare-feu

```bash
sudo ufw allow 9443/tcp
```

### 4. Créer le compte administrateur

Ouvrir `https://<adresse-du-serveur>:9443` (accepter le certificat autosigné) et créer le compte administrateur **dans les 5 minutes** suivant le démarrage. Passé ce délai, Portainer se verrouille par sécurité : le redémarrer (`sudo docker restart portainer`).

Choisir ensuite l'environnement **local** pour gérer le Docker de la machine.

## Vérification

```bash
sudo docker ps --filter name=portainer
```

Dans Portainer, *Home → local* affiche les conteneurs, images et volumes de l'hôte.

## Mise à jour

```bash
sudo docker stop portainer
sudo docker rm portainer
sudo docker pull portainer/portainer-ce:lts
```

Puis relancer la commande de l'étape 2 : les données sont conservées dans le volume `portainer_data`.

## Points d'attention

- Le script suppose que Docker est déjà installé : sinon, il s'arrête dès la première commande `docker`.
- Il n'ouvre aucun port dans le pare-feu et publie le port 8000, inutile sans agents Edge.
- Portainer a accès au socket Docker, c'est-à-dire des droits root sur l'hôte : protéger son compte administrateur et ne pas l'exposer sur Internet.

## Sources

- [Installer Portainer CE sous Linux](https://docs.portainer.io/start/install-ce/server/docker/linux)
- [Documentation Portainer](https://docs.portainer.io/)
