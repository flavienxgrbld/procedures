# Seafile — procédure d'installation

## Description

Seafile est une plateforme libre de synchronisation et de partage de fichiers, réputée pour sa rapidité : bibliothèques synchronisées, partage par lien, versions des fichiers, chiffrement côté client et édition collaborative de documents (SeaDoc). Cette procédure installe Seafile 13 Community Edition avec les fichiers Docker Compose officiels.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Docker Compose officiel (Seafile, MariaDB, Redis, Caddy, SeaDoc) |
| **Dossier** | `/opt/seafile` |
| **Ports** | 80/tcp et 443/tcp (Caddy) |
| **Script** | `install_seafile.sh` |

## Prérequis

- Docker et Docker Compose (procédure `docker`).
- 2 Go de RAM au minimum.
- Un nom de domaine pour HTTPS (ici `cloud.exemple.fr`), ou l'adresse IP du serveur pour un labo en HTTP.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/seafile
sudo bash install_seafile.sh
```

Lire les points d'attention : l'archive téléchargée par le script n'existe pas.

## Installation manuelle

### 1. Télécharger les fichiers officiels

```bash
sudo mkdir -p /opt/seafile
cd /opt/seafile
sudo wget -O .env https://manual.seafile.com/13.0/repo/docker/ce/env
sudo wget https://manual.seafile.com/13.0/repo/docker/ce/seafile-server.yml
sudo wget https://manual.seafile.com/13.0/repo/docker/seadoc.yml
sudo wget https://manual.seafile.com/13.0/repo/docker/caddy.yml
```

### 2. Adapter `.env`

```ini
SEAFILE_SERVER_HOSTNAME=cloud.exemple.fr
SEAFILE_SERVER_PROTOCOL=https
TIME_ZONE=Europe/Paris
JWT_PRIVATE_KEY=<chaîne aléatoire : openssl rand -base64 40>
SEAFILE_MYSQL_DB_PASSWORD=MotDePasseBase
INIT_SEAFILE_MYSQL_ROOT_PASSWORD=MotDePasseRootBase
INIT_SEAFILE_ADMIN_EMAIL=admin@exemple.fr
INIT_SEAFILE_ADMIN_PASSWORD=MotDePasseAdmin
```

Pour un labo sans domaine : `SEAFILE_SERVER_HOSTNAME=<adresse IP>` et `SEAFILE_SERVER_PROTOCOL=http`.

### 3. Démarrer

```bash
sudo docker compose up -d
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

Le premier démarrage initialise les bases (une à deux minutes). Caddy obtient automatiquement le certificat HTTPS si le domaine pointe vers le serveur.

### 4. Se connecter

Ouvrir `https://cloud.exemple.fr` avec le compte administrateur défini dans `.env`, puis créer les utilisateurs dans *Administration système → Utilisateurs*. Les clients de synchronisation Seafile (Windows, macOS, Linux, mobile) utilisent la même adresse.

## Vérification

```bash
sudo docker compose ps
sudo docker compose logs -f seafile
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/opt/seafile/.env` | Configuration du déploiement |
| `/opt/seafile-data/` | Données Seafile (fichiers, configuration, journaux) |
| `/opt/seafile-mysql/db/` | Bases MariaDB |

## Points d'attention

- Le script télécharge une archive « x86-64 » depuis le dépôt `seafile-rpi`, consacré aux versions Raspberry Pi : l'adresse renvoie une erreur 404 (vérifié le 13/10/2026), donc le script s'arrête.
- Même avec une archive valide, il n'exécute pas l'assistant de configuration (`setup-seafile-mysql.sh`), ne crée pas de service et ne configure pas de serveur web : Seafile ne démarre pas.
- Sauvegarder à la fois les bases MariaDB et `/opt/seafile-data`.

## Sources

- [Installer Seafile CE avec Docker](https://manual.seafile.com/latest/setup/setup_ce_by_docker/)
- [Manuel Seafile](https://manual.seafile.com/latest/)
