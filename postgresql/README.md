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

Par défaut, le script installe PostgreSQL depuis les paquets de la distribution (et initialise la base sur RHEL et Arch). Options :

```bash
# Dernière version (dépôt officiel PGDG), base et utilisateur dédiés, accès depuis le réseau local
sudo PG_PGDG=oui PG_DB=appli_db PG_USER=appli PG_NETWORK=oui bash install_postgresql.sh
```

Avec `PG_DB` et `PG_USER`, il crée la base et l'utilisateur (mot de passe aléatoire dans `/root/postgresql_<base>.txt`). Avec `PG_NETWORK=oui`, il fait les étapes 3 à 5 : écoute sur l'adresse du serveur, ligne `scram-sha-256` pour le réseau local dans `pg_hba.conf`, port 5432 ouvert à ce réseau seulement.

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

- Les applications doivent utiliser leur propre utilisateur, limité à leur base : ne pas donner de mot de passe au super-utilisateur `postgres` pour un usage applicatif.
- N'ouvrir le port 5432 qu'au réseau qui en a besoin, jamais à Internet.
- Mise à jour majeure (ex. 16 vers 17) : les données doivent être migrées (`pg_upgradecluster` sur Debian/Ubuntu).
- Relu et mis à jour le 12/11/2026.

## Sources

- [PostgreSQL sur Debian](https://www.postgresql.org/download/linux/debian/)
- [Documentation PostgreSQL](https://www.postgresql.org/docs/current/)
