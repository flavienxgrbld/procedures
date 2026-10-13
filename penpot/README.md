# Penpot — procédure d'installation

## Description

Penpot est un outil libre de design d'interfaces et de prototypage, utilisé dans le navigateur, alternative à Figma : maquettes, composants, prototypes interactifs et inspection du code pour les développeurs. Cette procédure l'installe avec le fichier Docker Compose officiel.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Docker Compose officiel (frontend, backend, exporter, PostgreSQL, Valkey) |
| **Dossier** | `/opt/penpot` |
| **Ports** | 9001/tcp |
| **Script** | `install_penpot.sh` |

## Prérequis

- Docker et Docker Compose (procédure `docker`).
- 4 Go de RAM au minimum.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/penpot
sudo bash install_penpot.sh
```

Lire les points d'attention : l'image utilisée par le script n'existe pas.

## Installation manuelle

### 1. Télécharger le fichier Compose officiel

```bash
sudo mkdir -p /opt/penpot
cd /opt/penpot
sudo wget -O docker-compose.yaml https://raw.githubusercontent.com/penpot/penpot/main/docker/images/docker-compose.yaml
```

### 2. Adapter l'adresse publique

Dans `docker-compose.yaml`, remplacer la valeur de `PENPOT_PUBLIC_URI` par l'adresse utilisée dans le navigateur :

```yaml
PENPOT_PUBLIC_URI: http://<adresse-du-serveur>:9001
```

Le fichier officiel contient déjà l'option `disable-secure-session-cookies` dans `PENPOT_FLAGS`, nécessaire tant que Penpot est servi en HTTP. La retirer une fois HTTPS en place.

### 3. Démarrer

```bash
sudo docker compose -p penpot -f docker-compose.yaml up -d
sudo ufw allow 9001/tcp
```

### 4. Créer un compte

Ouvrir `http://<adresse-du-serveur>:9001` et créer un compte. La vérification par e-mail est désactivée dans le fichier officiel (`disable-email-verification`), ce qui permet de commencer sans serveur SMTP.

Une fois les comptes de l'équipe créés, interdire les nouvelles inscriptions en ajoutant `disable-registration` à `PENPOT_FLAGS` (services frontend et backend), puis redémarrer.

## Vérification

```bash
sudo docker compose -p penpot ps
sudo docker compose -p penpot logs -f penpot-backend
```

## Mise à jour

```bash
cd /opt/penpot
sudo docker compose -p penpot pull
sudo docker compose -p penpot up -d
```

## Points d'attention

- Le script lance l'image `penpotapp/penpot`, qui n'existe pas sur Docker Hub (vérifié le 13/10/2026) : le téléchargement échoue. Penpot se compose de plusieurs services (frontend, backend, exporter) avec PostgreSQL et Valkey, décrits dans le Compose officiel.
- Il publie Penpot sur le port 80 de l'hôte, en conflit avec un éventuel serveur web.
- En production, placer Penpot derrière un proxy HTTPS (procédures `nginx` et `certbot`), avec la prise en charge des WebSockets.

## Sources

- [Installer Penpot avec Docker](https://help.penpot.app/technical-guide/getting-started/docker/)
- [Configuration de Penpot](https://help.penpot.app/technical-guide/configuration/)
