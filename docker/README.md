# Installation de Docker

## Description
Docker est une plateforme de conteneurisation open source permettant de créer, déployer et exécuter des applications dans des conteneurs isolés. Elle facilite le développement, les tests et la mise en production.

## Prérequis
- Système d'exploitation : Ubuntu/Debian, CentOS/RHEL, SUSE, Arch Linux
- Architecture : x86_64 (amd64)
- Accès : root ou sudo
- Connexion Internet
- Noyau Linux version 3.10 ou supérieure

## Installation

### Méthode automatique (recommandée)

```bash
bash install_docker.sh
```

### Installation manuelle (étapes détaillées)

#### 1. Mise à jour du système
```bash
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
```

#### 2. Installation de Docker

##### Ubuntu / Debian
```bash
sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release -y

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
```

##### CentOS / RHEL
```bash
sudo yum install docker docker-compose -y
```

##### SUSE
```bash
sudo zypper install docker docker-compose -y
```

##### Arch Linux
```bash
sudo pacman -S docker docker-compose
```

#### 3. Activation et démarrage du service
```bash
sudo systemctl enable docker
sudo systemctl start docker
```

#### 4. Ajout de l'utilisateur au groupe Docker
```bash
sudo usermod -aG docker $USER
```

⚠️ Déconnectez-vous puis reconnectez-vous pour appliquer les changements.

## Configuration

### Démarrage automatique
Docker démarre automatiquement au démarrage du système.

### Configuration avancée du démon
Fichier :
```bash
sudo nano /etc/docker/daemon.json
```

Exemple :
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Redémarrage :
```bash
sudo systemctl restart docker
```

## Utilisation de base

```bash
# Vérifier les versions
docker --version
docker compose version

# Tester Docker
docker run hello-world

# Télécharger une image
docker pull nginx

# Lister les conteneurs
docker ps -a

# Lancer un conteneur
docker run -d nginx

# Nettoyage système
docker system prune
```

## Docker Compose

```bash
# Lancer une stack
docker compose up -d

# Arrêter une stack
docker compose down
```

## Vérification

```bash
# État du service
sudo systemctl status docker

# Test rapide
docker run hello-world

# Logs Docker
sudo journalctl -u docker -f
```

## Dépannage

```bash
# Problèmes de permissions
groups $USER

# Ajouter docker si nécessaire
sudo usermod -aG docker $USER

# Vérifier utilisation disque
docker system df

# Logs détaillés
sudo journalctl -u docker --no-pager
```

## Sécurité

- Ne pas exécuter systématiquement en root
- Utiliser uniquement des images fiables
- Scanner les images avant production
- Limiter les privilèges des conteneurs

## Documentation
- Site officiel : https://www.docker.com/
- Documentation : https://docs.docker.com/
- Docker Compose : https://docs.docker.com/compose/

## Notes
- Docker simplifie le déploiement d'applications
- Nettoyez régulièrement les ressources inutilisées :
```bash
docker system prune -a
```
- Pour la production, envisager Kubernetes ou Docker Swarm