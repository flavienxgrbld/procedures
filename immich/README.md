# Immich — procédure d'installation

## Description

Immich est une solution auto-hébergée de sauvegarde et de gestion de photos et de vidéos, alternative à Google Photos : envoi automatique depuis le téléphone, albums partagés, reconnaissance des visages et recherche intelligente. Cette procédure l'installe avec le fichier Docker Compose officiel.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Docker Compose officiel (serveur, apprentissage automatique, Valkey, PostgreSQL) |
| **Dossier** | `/opt/immich` |
| **Ports** | 2283/tcp |
| **Script** | `install_immich.sh` |

## Prérequis

- Docker et le plugin Docker Compose installés (voir la procédure `docker`).
- 4 Go de RAM au minimum (6 Go conseillés) et 2 cœurs.
- De l'espace disque pour la bibliothèque de photos.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/immich
sudo bash install_immich.sh
```

Lire les points d'attention : le fichier Compose du script est incomplet et Immich ne démarre pas.

## Installation manuelle

### 1. Récupérer les fichiers officiels

```bash
sudo mkdir -p /opt/immich
cd /opt/immich
sudo wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
sudo wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env
```

### 2. Adapter le fichier `.env`

```bash
sudo nano .env
```

```ini
# Emplacement des photos et vidéos
UPLOAD_LOCATION=/srv/immich/library
# Emplacement de la base de données (disque local, pas un partage réseau)
DB_DATA_LOCATION=/opt/immich/postgres
# Fuseau horaire
TZ=Europe/Paris
# Mot de passe de la base (lettres et chiffres uniquement)
DB_PASSWORD=MotDePasseFort123
```

### 3. Démarrer

```bash
sudo docker compose up -d
sudo ufw allow 2283/tcp
```

Le premier démarrage télécharge plusieurs Go d'images.

### 4. Créer le compte administrateur

Ouvrir `http://<adresse-du-serveur>:2283`, cliquer sur **Getting Started** et créer le compte administrateur, puis les comptes des autres utilisateurs dans *Administration → Users*.

### 5. Connecter les téléphones

Installer l'application Immich (Android ou iOS), saisir l'URL `http://<adresse-du-serveur>:2283`, se connecter, puis activer la sauvegarde automatique.

## Vérification

```bash
cd /opt/immich
sudo docker compose ps
```

Les 4 conteneurs `immich_server`, `immich_machine_learning`, `immich_redis` et `immich_postgres` doivent être actifs (*healthy*).

## Mise à jour

```bash
cd /opt/immich
sudo docker compose pull
sudo docker compose up -d
```

Lire les notes de version avant chaque mise à jour : certaines demandent une modification du fichier Compose.

## Dépannage

- Journaux : `sudo docker compose logs -f immich-server`.
- Sauvegarder à la fois `UPLOAD_LOCATION` et la base. Immich crée des sauvegardes de la base dans `UPLOAD_LOCATION/backups`.

## Points d'attention

- Le fichier Compose du script ne contient que le serveur et PostgreSQL 15. Il manque Redis/Valkey et le service d'apprentissage automatique, et la base doit utiliser l'image PostgreSQL d'Immich, avec ses extensions de recherche vectorielle : Immich ne démarre pas.
- Le script publie le port 3001 et monte `/usr/src/app/upload`, utilisés par les anciennes versions. Les versions actuelles écoutent sur 2283 et stockent dans `/data`.
- Ne pas placer la base de données (`DB_DATA_LOCATION`) sur un partage réseau (NFS, SMB) : elle risque d'être corrompue.

## Sources

- [Installation avec Docker Compose](https://docs.immich.app/install/docker-compose)
- [Documentation Immich](https://docs.immich.app/)
