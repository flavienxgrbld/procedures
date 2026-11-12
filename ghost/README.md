# Ghost — procédure d'installation

## Description

Ghost est une plateforme de publication moderne pour blogs et newsletters, rapide et centrée sur l'écriture, avec gestion des membres et des abonnements. Cette procédure suit la méthode officielle : Ghost-CLI sur Ubuntu, derrière Nginx, avec MySQL 8.

| | |
|---|---|
| **Systèmes** | Ubuntu 22.04 / 24.04 (méthode officielle) |
| **Méthode** | Ghost-CLI + Node.js + Nginx + MySQL 8 |
| **Dossier** | `/var/www/ghost` |
| **Ports** | 80/tcp et 443/tcp (Nginx) ; Ghost écoute en interne sur 2368 |
| **Script** | `install_ghost.sh` |

## Prérequis

- Un serveur Ubuntu avec 1 Go de RAM au minimum.
- Un nom de domaine pointant vers le serveur (pour HTTPS).
- Un utilisateur non-root avec `sudo`, qui **ne doit pas s'appeler `ghost`**.

## Installation automatique

Sur Ubuntu 22.04 ou 24.04, avec un nom de domaine public qui pointe déjà vers le serveur :

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/ghost
sudo GHOST_URL=https://blog.exemple.fr GHOST_SSL_EMAIL=admin@exemple.fr bash install_ghost.sh
```

Le script installe Nginx, MySQL 8 et Node.js 22, crée une base et un utilisateur MySQL dédiés, installe Ghost-CLI, crée le compte d'administration `ghostadmin`, puis lance `ghost install` sans question (Nginx, certificat Let's Encrypt, service systemd). Avec une adresse en `http://` (labo sans domaine public), le HTTPS n'est pas configuré. Les identifiants de la base sont enregistrés dans `/root/ghost_identifiants.txt`.

## Installation manuelle

### 1. Créer un utilisateur d'administration

```bash
sudo adduser ghostadmin
sudo usermod -aG sudo ghostadmin
su - ghostadmin
```

Ne pas appeler ce compte `ghost` : Ghost-CLI crée lui-même un utilisateur `ghost` pour faire tourner le service.

```bash
# (suite dans la session ghostadmin)
```

### 2. Installer Nginx et MySQL 8

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx mysql-server
sudo ufw allow 'Nginx Full'
```

Créer la base et un utilisateur MySQL dédié à Ghost :

```bash
sudo mysql
```

```sql
CREATE DATABASE ghost_prod CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE USER 'ghost_db'@'localhost' IDENTIFIED BY 'MotDePasseFort';
GRANT ALL PRIVILEGES ON ghost_prod.* TO 'ghost_db'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3. Installer Node.js (version prise en charge par Ghost)

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
sudo apt install -y nodejs
node -v
```

### 4. Installer Ghost-CLI

```bash
sudo npm install -g ghost-cli@latest
```

### 5. Préparer le dossier du site

```bash
sudo mkdir -p /var/www/ghost
sudo chown $USER:$USER /var/www/ghost
sudo chmod 775 /var/www/ghost
cd /var/www/ghost
```

### 6. Installer Ghost

```bash
ghost install
```

Réponses :

| Question | Réponse |
|---|---|
| Blog URL | `https://blog.exemple.fr` |
| MySQL hostname / username / password | `localhost` / `ghost_db` / mot de passe de l'étape 2 |
| Ghost database name | `ghost_prod` |
| Set up a ghost MySQL user? | `n` (l'utilisateur dédié existe déjà) |
| Set up Nginx? | `Y` |
| Set up SSL? | `Y` (adresse e-mail pour Let's Encrypt) |
| Set up systemd? | `Y` |
| Start Ghost? | `Y` |

### 7. Créer le compte propriétaire

Ouvrir `https://blog.exemple.fr/ghost`, puis créer le compte administrateur du site.

## Vérification

```bash
cd /var/www/ghost
ghost ls
ghost doctor
```

## Commandes utiles

| Commande | Rôle |
|---|---|
| `ghost restart` | Redémarrer |
| `ghost update` | Mettre à jour Ghost |
| `ghost log` | Afficher les journaux |
| `ghost backup` | Sauvegarder contenu et paramètres |

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/var/www/ghost/config.production.json` | Configuration (URL, base, e-mail) |
| `/var/www/ghost/content/` | Thèmes, images, données |

## Dépannage

- `ghost doctor` détecte la plupart des problèmes (droits, version de Node.js, configuration système).
- Pour envoyer des e-mails (invitations, newsletters), configurer un SMTP dans `config.production.json` (section `mail`).

## Points d'attention

- Ghost ne prend en charge en production qu'Ubuntu, MySQL 8 (pas MariaDB) et une version LTS de Node.js prise en charge (22 au 12/11/2026).
- La commande `ghost` se lance toujours depuis le compte d'administration (`ghostadmin`), jamais en root.
- Le certificat Let's Encrypt n'est obtenu que si le domaine pointe vers le serveur et que les ports 80 et 443 sont joignables depuis Internet.
- Relu et mis à jour le 12/11/2026 (Ghost 6).

## Sources

- [Installer Ghost sur Ubuntu](https://docs.ghost.org/install/ubuntu/)
- [Référence Ghost-CLI](https://docs.ghost.org/ghost-cli)
