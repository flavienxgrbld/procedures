# Redis — procédure d'installation

## Description

Redis est une base de données clé/valeur en mémoire, extrêmement rapide, utilisée comme cache, gestionnaire de sessions, file de messages ou compteur en temps réel. Beaucoup d'applications web l'utilisent (Nextcloud, GitLab, Paperless, Immich…). Cette procédure l'installe et le sécurise par mot de passe.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu |
| **Méthode** | Paquet de la distribution `redis-server` |
| **Ports** | 6379/tcp |
| **Script** | `install_redis.sh` |

## Prérequis

- Un accès root.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/redis
sudo bash install_redis.sh
```

Le script installe `redis-server`, règle `requirepass` (mot de passe aléatoire, enregistré dans `/root/redis_identifiants.txt`), `maxmemory` et la politique d'éviction sans passer par `sed` (aucun problème de caractères spéciaux), vérifie la connexion puis redémarre le service. Redis reste à l'écoute de `127.0.0.1` ; avec `REDIS_CLIENTS="192.168.1.21"`, il écoute aussi sur l'adresse du serveur et seules ces machines sont autorisées dans `ufw`. Variables facultatives : `REDIS_PASS`, `REDIS_MAXMEMORY`, `REDIS_POLICY` (`noeviction` par défaut, `allkeys-lru` pour un cache).

## Installation manuelle

### 1. Installer Redis

```bash
sudo apt update
sudo apt install -y redis-server
sudo systemctl enable --now redis-server
```

### 2. Sécuriser la configuration

Dans `/etc/redis/redis.conf` :

```conf
# Écoute : locale uniquement, ou ajouter l'adresse du serveur pour le réseau
bind 127.0.0.1 -::1

# Mot de passe (long et aléatoire : openssl rand -base64 32)
requirepass UnMotDePasseLongEtAleatoire

# Mémoire maximale et politique d'éviction (usage en cache)
maxmemory 256mb
maxmemory-policy allkeys-lru
```

```bash
sudo systemctl restart redis-server
```

### 3. (Optionnel) Accès depuis le réseau

Ajouter l'adresse du serveur à `bind` (par exemple `bind 127.0.0.1 192.168.1.50`), puis n'autoriser que les machines qui en ont besoin :

```bash
sudo ufw allow from 192.168.1.21 to any port 6379 proto tcp
```

## Vérification

```bash
redis-cli ping                       # NOAUTH : un mot de passe est bien exigé
redis-cli -a 'UnMotDePasseLongEtAleatoire' ping     # PONG
redis-cli -a '...' INFO memory | grep maxmemory_human
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/redis/redis.conf` | Configuration |
| `/var/lib/redis/dump.rdb` | Sauvegarde des données sur disque (instantanés) |
| `/var/log/redis/redis-server.log` | Journal |

## Points d'attention

- Un Redis exposé sur Internet est une cible très courante : ne l'ouvrir qu'aux machines clientes.
- La politique `allkeys-lru` supprime des clés quand la mémoire est pleine : elle convient à un cache, pas à des données à conserver (garder `noeviction`).
- Les applications utilisent le mot de passe dans leur configuration (`redis://:motdepasse@serveur:6379`).
- Relu et mis à jour le 12/11/2026.

## Sources

- [Sécurité de Redis](https://redis.io/docs/latest/operate/oss_and_stack/management/security/)
- [Fichier de configuration de Redis](https://redis.io/docs/latest/operate/oss_and_stack/management/config/)
