# MongoDB — procédure d'installation

## Description

MongoDB est une base de données NoSQL orientée documents : les données sont stockées sous forme de documents JSON (BSON), sans schéma fixe, ce qui convient aux applications web et aux données semi-structurées. Cette procédure installe MongoDB Community 8.0 depuis le dépôt officiel et active l'authentification.

| | |
|---|---|
| **Systèmes** | Debian 12, Ubuntu 22.04 / 24.04 (64 bits) |
| **Méthode** | Dépôt officiel `repo.mongodb.org` |
| **Version** | 8.0 |
| **Ports** | 27017/tcp |
| **Script** | `install_mongodb.sh` |

## Prérequis

- Un processeur 64 bits avec les instructions AVX (à vérifier en VM : `grep -c avx /proc/cpuinfo` doit être supérieur à 0).
- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/mongodb
sudo bash install_mongodb.sh
```

Lire les points d'attention : le script installe une version en fin de vie, depuis un dépôt prévu pour Ubuntu 20.04 seulement.

## Installation manuelle

### 1. Ajouter le dépôt MongoDB 8.0

```bash
sudo apt update
sudo apt install -y gnupg curl
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
```

Debian 12 :

```bash
echo "deb [signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" \
  | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
```

Ubuntu 24.04 (remplacer `noble` par `jammy` pour 22.04) :

```bash
echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" \
  | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
```

### 2. Installer et démarrer

```bash
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl enable --now mongod
```

### 3. Créer un administrateur

```bash
mongosh
```

```javascript
use admin
db.createUser({ user: "admin", pwd: passwordPrompt(), roles: [ "root" ] })
exit
```

### 4. Activer l'authentification

Dans `/etc/mongod.conf` :

```yaml
net:
  port: 27017
  bindIp: 127.0.0.1,192.168.1.50

security:
  authorization: enabled
```

`bindIp` ajoute l'adresse du serveur pour autoriser les connexions depuis le réseau.

```bash
sudo systemctl restart mongod
sudo ufw allow from 192.168.1.0/24 to any port 27017 proto tcp
```

### 5. Créer un utilisateur applicatif

```bash
mongosh -u admin -p --authenticationDatabase admin
```

```javascript
use appdb
db.createUser({ user: "app", pwd: passwordPrompt(), roles: [ { role: "readWrite", db: "appdb" } ] })
```

## Vérification

```bash
systemctl status mongod
mongosh -u admin -p --authenticationDatabase admin --eval 'db.runCommand({ ping: 1 })'
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/mongod.conf` | Configuration |
| `/var/lib/mongodb/` | Données |
| `/var/log/mongodb/mongod.log` | Journal |

## Dépannage

- **`mongod` s'arrête aussitôt avec « Illegal instruction »** : le processeur (ou le CPU virtuel) ne fournit pas AVX. Sur Proxmox, utiliser le type de CPU `host`.
- Sauvegarde : `mongodump -u admin -p --authenticationDatabase admin --out /srv/sauvegardes/mongo-$(date +%F)`.

## Points d'attention

- Le script installe MongoDB 5.0, qui n'est plus maintenu, depuis le dépôt `ubuntu focal` (Ubuntu 20.04), quelle que soit la distribution : sur Debian 12 ou Ubuntu 24.04, l'installation échoue faute de bibliothèques compatibles. Il utilise aussi `apt-key`, retiré des distributions récentes.
- Il ouvre le port 27017 à tout le réseau sans activer l'authentification. MongoDB n'écoute que sur `127.0.0.1` par défaut : il faut à la fois `bindIp` et `authorization` (étape 4).

## Sources

- [Installer MongoDB sur Debian](https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-debian/)
- [Installer MongoDB sur Ubuntu](https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-ubuntu/)
- [Activer le contrôle d'accès](https://www.mongodb.com/docs/manual/tutorial/configure-scram-client-authentication/)
