# Installation de Discourse

## Description
Discourse est une plateforme de forum moderne, open source, conçue pour faciliter les discussions en ligne avec une interface intuitive et des fonctionnalités avancées (notifications, modération, SSO, etc.).

## Prérequis
- Système d'exploitation : Ubuntu/Debian Linux (Ubuntu 20.04+ recommandé)
- Accès : root ou sudo
- Connexion Internet
- Nom de domaine pointant vers le serveur
- Minimum 2 Go de RAM (4 Go recommandés)
- Docker installé (requis)

## Installation

### Méthode automatique (recommandée)

```bash
bash install_discourse.sh
```

### Installation manuelle (étapes détaillées)

#### 1. Mise à jour du système
```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. Installation de Docker
```bash
sudo apt install docker.io git curl -y
sudo systemctl enable docker
sudo systemctl start docker
```

#### 3. Téléchargement de Discourse
```bash
cd /var/discourse
sudo git clone https://github.com/discourse/discourse_docker.git .
```

#### 4. Lancement de l'installation
```bash
sudo ./discourse-setup
```

Lors de l'installation, vous devrez renseigner :
- Nom de domaine (ex: forum.votre-domaine.com)
- Adresse email administrateur
- Paramètres SMTP (obligatoire pour les emails)
- Configuration HTTPS (Let's Encrypt automatique)

#### 5. Démarrage du conteneur
```bash
cd /var/discourse
sudo ./launcher start app
```

## Configuration

### Gestion du conteneur
```bash
# Redémarrer Discourse
sudo ./launcher restart app

# Arrêter Discourse
sudo ./launcher stop app

# Mettre à jour Discourse
sudo ./launcher rebuild app
```

### Fichiers importants
- `/var/discourse/containers/app.yml` — configuration principale
- `/var/discourse/shared/` — données persistantes

## Vérification

```bash
# Vérifier Docker
sudo systemctl status docker

# Vérifier Discourse
cd /var/discourse
sudo ./launcher status

# Tester accès web
curl -I https://votre-domaine.com
```

Accédez ensuite à :
```
https://votre-domaine.com
```

Créez votre compte administrateur lors du premier accès.

## Dépannage

```bash
# Logs du conteneur
cd /var/discourse
sudo ./launcher logs app

# Vérifier les conteneurs Docker
docker ps -a

# Redémarrer Docker
sudo systemctl restart docker
```

## Documentation
- Site officiel : https://www.discourse.org/
- Documentation : https://meta.discourse.org/
- GitHub : https://github.com/discourse/discourse

## Notes
- Discourse fonctionne exclusivement avec Docker
- Un SMTP valide est obligatoire pour l'envoi d'emails
- HTTPS est automatiquement configuré via Let's Encrypt
- Prévoir suffisamment de RAM pour de bonnes performances