# PostgreSQL — procédure d'installation

## Description

PostgreSQL est un système de gestion de base de données relationnelle libre, réputé pour sa robustesse, sa conformité au standard SQL et ses extensions (PostGIS, recherche plein texte, JSON). Il sert de base à de nombreuses applications (Odoo, Mattermost, Synapse, Keycloak…). Cette procédure l'installe, crée une base et un utilisateur, puis ouvre l'accès depuis le réseau local.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu, RHEL/Fedora, openSUSE, Arch |
| **Méthode** | Paquets de la distribution (ou dépôt officiel PGDG pour la dernière version) |
| **Ports** | 5432/tcp |
| **Script** | `install_postgresql.sh` |

## Prérequis

- Un accès root.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/postgresql
sudo bash install_postgresql.sh
```

Le script installe PostgreSQL et demande un mot de passe pour le compte `postgres`. Les étapes 3 à 5 restent à faire pour un accès depuis le réseau.

## Installation manuelle

### 1. Installer PostgreSQL

```bash
sudo apt update
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql
psql --version
```

Pour une version plus récente que celle de la distribution, ajouter le dépôt officiel PGDG :

```bash
sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
```

### 2. Créer un utilisateur et une base

```bash
sudo -u postgres createuser --pwprompt appli
sudo -u postgres createdb --owner=appli appli_db
```

Ou en SQL :

```bash
sudo -u postgres psql
```

```sql
CREATE USER appli WITH PASSWORD 'MotDePasseFort';
CREATE DATABASE appli_db OWNER appli;
\q
```

### 3. Écouter sur le réseau

Dans `/etc/postgresql/<version>/main/postgresql.conf` :

```conf
listen_addresses = 'localhost,192.168.1.50'
```

### 4. Autoriser les connexions distantes

Dans `/etc/postgresql/<version>/main/pg_hba.conf`, ajouter :

```conf
# TYPE  BASE       UTILISATEUR  ADRESSE           MÉTHODE
host    appli_db   appli        192.168.1.0/24    scram-sha-256
```

```bash
sudo systemctl restart postgresql
```

### 5. Ouvrir le pare-feu au seul réseau local

```bash
sudo ufw allow from 192.168.1.0/24 to any port 5432 proto tcp
```

## Vérification

```bash
sudo -u postgres psql -c "SELECT version();"
psql -h 192.168.1.50 -U appli -d appli_db -c '\conninfo'
```

## Commandes utiles

| Commande | Rôle |
|---|---|
| `\l` / `\du` / `\dt` (dans `psql`) | Lister bases / rôles / tables |
| `pg_dump -U appli -h localhost appli_db > sauvegarde.sql` | Sauvegarder une base |
| `psql -U appli -h localhost appli_db < sauvegarde.sql` | Restaurer |
| `pg_lsclusters` | Voir les instances et leur état (Debian/Ubuntu) |

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/postgresql/<version>/main/postgresql.conf` | Configuration du serveur |
| `/etc/postgresql/<version>/main/pg_hba.conf` | Règles d'authentification |
| `/var/lib/postgresql/<version>/main/` | Données |
| `/var/log/postgresql/` | Journaux |

## Points d'attention

- Le script ouvre le port 5432 à tout le réseau, alors que PostgreSQL n'écoute que sur `localhost` par défaut : l'ouverture ne sert à rien tant que `listen_addresses` et `pg_hba.conf` ne sont pas modifiés (étapes 3 et 4). Une fois ces fichiers modifiés, il faut limiter l'accès au réseau local.
- Il donne un mot de passe au super-utilisateur `postgres`. Les applications doivent utiliser leur propre utilisateur, limité à leur base (étape 2).
- Sur openSUSE et Arch, il ne lance pas toujours l'initialisation de la base (`initdb`) : le service peut refuser de démarrer.

## Sources

- [PostgreSQL sur Debian](https://www.postgresql.org/download/linux/debian/)
- [Documentation PostgreSQL](https://www.postgresql.org/docs/current/)
